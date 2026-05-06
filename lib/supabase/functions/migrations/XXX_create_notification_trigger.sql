-- ===================================================================
-- TRIGGER: Llamar Edge Function cuando hay nueva notificación
-- ===================================================================

-- ✅ Función que invoca la Edge Function vía HTTP
CREATE OR REPLACE FUNCTION public.trigger_send_fcm_notification()
RETURNS trigger AS $$
DECLARE
  v_fcm_token TEXT;
  v_edge_function_url TEXT;
  v_http_response RECORD;
  v_notification_data JSONB;
BEGIN
  -- 🔹 URL de la Edge Function (ajustar con tu project ref)
  v_edge_function_url := 'https://ihvbmppztoqkntifwvfa.supabase.co/functions/v1/send-fcm-notification';
  
  -- 🔹 Obtener token FCM del usuario (último dispositivo activo)
  SELECT fcm_token INTO v_fcm_token
  FROM public.user_devices
  WHERE user_id = NEW.user_id
    AND fcm_token IS NOT NULL
  ORDER BY last_used_at DESC
  LIMIT 1;
  
  -- Si no hay token, salir silenciosamente
  IF v_fcm_token IS NULL THEN
    RAISE NOTICE 'Usuario sin token FCM: %', NEW.user_id;
    RETURN NEW;
  END IF;
  
  -- 🔹 Construir payload para la Edge Function
  v_notification_data := jsonb_build_object(
    'token', v_fcm_token,
    'notificationType', NEW.type,
    'reelId', NEW.data->>'reel_id',
    'userId', NEW.user_id::text,
    'buyerName', NEW.data->>'buyer_name',
    'itemTitle', NEW.data->>'item_title',
    'questionId', NEW.data->>'question_id'
  );
  
  -- 🔹 Llamar a la Edge Function vía HTTP (pg_net para la llamada HTTP, no para FCM)
  BEGIN
    SELECT * INTO v_http_response
    FROM net.http_post(
      url := v_edge_function_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.supabase_anon_key', true)
      ),
      body := v_notification_data,
      timeout_milliseconds := 10000
    );
    
    -- ✅ Log de respuesta
    RAISE NOTICE 'Edge Function response: status=%, body=%', 
      v_http_response.status, 
      v_http_response.content;
      
  EXCEPTION WHEN OTHERS THEN
    -- ✅ No fallar el trigger si la llamada HTTP falla
    RAISE NOTICE 'Error calling Edge Function: %', SQLERRM;
  END;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 🔹 Crear trigger en la tabla notifications
DROP TRIGGER IF EXISTS trigger_send_fcm ON public.notifications;

CREATE TRIGGER trigger_send_fcm
AFTER INSERT ON public.notifications
FOR EACH ROW
EXECUTE FUNCTION public.trigger_send_fcm_notification();

-- ✅ Grants
GRANT EXECUTE ON FUNCTION public.trigger_send_fcm_notification TO authenticated;