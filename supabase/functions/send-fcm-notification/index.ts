// supabase/functions/send-fcm-notification/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { initializeApp, cert, getApp } from "npm:firebase-admin/app";
import { getMessaging } from "npm:firebase-admin/messaging";

// 🔹 Singleton pattern para evitar re-inicializar Firebase en cada request
let messaging: ReturnType<typeof getMessaging> | null = null;

function getFirebaseMessaging() {
  if (messaging) return messaging;
  
  // 🔹 Recuperar el secreto (contenido del JSON de service account)
  const serviceAccountRaw = Deno.env.get("FCM_SERVICE_ACCOUNT");
  if (!serviceAccountRaw) {
    throw new Error("FCM_SERVICE_ACCOUNT secret not configured");
  }
  
  const serviceAccount = JSON.parse(serviceAccountRaw);
  
  // 🔹 Inicializar Firebase Admin SDK
  try {
    const app = initializeApp({
      credential: cert(serviceAccount),
    });
    messaging = getMessaging(app);
  } catch (error) {
    // Si ya está inicializada (hot reload), obtener instancia existente
    if (error.message?.includes("already exists")) {
      const app = getApp();
      messaging = getMessaging(app);
    } else {
      throw error;
    }
  }
  
  return messaging!;
}

// 🔹 Handler principal de la Edge Function
serve(async (req: Request) => {
  try {
    // ✅ CORS headers para permitir llamadas desde Supabase
    if (req.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST",
          "Access-Control-Allow-Headers": "Content-Type, Authorization",
        },
      });
    }

    // 🔹 Parsear payload recibido desde el trigger de Supabase
    const payload = await req.json();
    
    const {
      token,           // FCM token del dispositivo
      notificationType, // 'nuevo_lo_quiero', 'nueva_pregunta_reel', etc.
      reelId,
      userId,
      buyerName,
      itemTitle,
      questionId,
    } = payload;

    if (!token || !notificationType || !reelId) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: token, notificationType, reelId" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // 🔹 Construir mensaje según tipo de notificación
    const title = {
      'nuevo_lo_quiero': '¡Nuevo Lo Quiero! ❤️',
      'nueva_pregunta_reel': 'Nueva Pregunta 💬',
      'respuesta_a_pregunta': 'Nueva Respuesta ✅',
      'nuevo_followup_pregunta': 'Nuevo Mensaje 💬',
    }[notificationType] || 'Nueva Notificación';

    const body = {
      'nuevo_lo_quiero': `${buyerName} está interesado en "${itemTitle}"`,
      'nueva_pregunta_reel': 'Alguien preguntó sobre tu reel',
      'respuesta_a_pregunta': 'El vendedor respondió tu pregunta',
      'nuevo_followup_pregunta': 'Hay un nuevo mensaje en tu conversación',
    }[notificationType] || 'Tienes una nueva notificación';

    // 🔹 Construir mensaje para FCM (API V1)
    const message = {
      notification: {
        title,
        body,
      },
      data: {
        type: notificationType,
        reel_id: reelId,
        user_id: userId || '',
        // ✅ Flag para abrir modal de preguntas automáticamente
        openQuestions: ['nueva_pregunta_reel', 'respuesta_a_pregunta', 'nuevo_followup_pregunta'].includes(notificationType).toString(),
        question_id: questionId || '',
      },
      token,
      android: {
        priority: "high",
        notification: {
          channelId: notificationType === 'nuevo_lo_quiero' ? 'lo_quiero_channel' : 'preguntas_channel',
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            category: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
      },
    };

    // 🔹 Enviar notificación vía Firebase Admin SDK
    const messagingInstance = getFirebaseMessaging();
    const response = await messagingInstance.send(message);

    // ✅ Éxito
    return new Response(
      JSON.stringify({ 
        success: true, 
        messageId: response,
        timestamp: new Date().toISOString()
      }),
      {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );

  } catch (error) {
    console.error("❌ [FCM Edge Function] Error:", error);
    
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message,
        timestamp: new Date().toISOString()
      }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  }
});