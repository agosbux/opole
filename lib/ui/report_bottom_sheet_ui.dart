import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:opole/controllers/session_controller.dart';
import 'package:opole/pages/splash_screen_page/api/create_report_api.dart';
import 'package:opole/pages/splash_screen_page/api/fetch_report_api.dart';
import 'package:opole/pages/splash_screen_page/model/fetch_report_model.dart' as report_model;
import 'package:opole/shimmer/report_bottom_sheet_shimmer_ui.dart';
import 'package:opole/utils/asset.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/database.dart';
import 'package:opole/utils/enums.dart';
import 'package:opole/utils/font_style.dart';
import 'package:opole/utils/utils.dart';

class ReportBottomSheetUi extends StatefulWidget {
  final String eventId;
  final int eventType;

  const ReportBottomSheetUi({
    super.key,
    required this.eventId,
    required this.eventType,
  });

  @override
  State<ReportBottomSheetUi> createState() => _ReportBottomSheetUiState();
}

class _ReportBottomSheetUiState extends State<ReportBottomSheetUi> {
  final RxInt selectedReportType = 0.obs;
  final RxBool isLoading = false.obs;
  List<report_model.Data> reportTypes = [];

  @override
  void initState() {
    super.initState();
    _fetchReportTypes();
  }

  Future<void> _fetchReportTypes() async {
    if (reportTypes.isNotEmpty) return;
    isLoading.value = true;

    final fetchReportModel = await FetchReportApi.callApi();
    if (fetchReportModel?.data != null) {
      reportTypes.addAll(fetchReportModel?.data ?? []);
    } else {
      // Usar strings literales en lugar de enum faltantes
      reportTypes.addAll(_getStaticReportTypes());
    }

    isLoading.value = false;
  }

  List<report_model.Data> _getStaticReportTypes() {
    return [
      report_model.Data(title: 'Spam'),
      report_model.Data(title: 'Contenido inapropiado'),
      report_model.Data(title: 'Acoso'),
      report_model.Data(title: 'Violencia'),
      report_model.Data(title: 'InfracciÃ³n de derechos'),
      report_model.Data(title: 'Otro'),
    ];
  }

  Future<void> _sendReport() async {
    if (selectedReportType.value >= reportTypes.length) {
      Utils.showToast('Por favor selecciona un motivo');
      return;
    }

    final loginUserId = GetStorage().read("loginUserId") ?? "";
    final reportReason = reportTypes[selectedReportType.value].title ?? "";

    setState(() => isLoading.value = true);

    final response = await CreateReportApi.callApi(
      loginUserId: loginUserId,
      reportReason: reportReason,
      eventType: widget.eventType,
      eventId: widget.eventId,
    );

    setState(() => isLoading.value = false);

    if (response == true) {
      Utils.showToast('Reporte enviado con Ã©xito');
      Navigator.pop(context);
    } else {
      Utils.showToast('Error al enviar el reporte');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      width: Get.width,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            height: 65,
            color: AppColor.grey_100,
            child: Row(
              children: [
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 4,
                      width: 35,
                      decoration: BoxDecoration(
                        color: AppColor.colorTextDarkGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Reportar',
                      style: AppFontStyle.styleW700(AppColor.black, 17),
                    ),
                  ],
                ).paddingOnly(left: 50),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 30,
                    width: 30,
                    margin: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColor.transparent,
                      border: Border.all(color: AppColor.black),
                    ),
                    child: Center(
                      child: Image.asset(
                        width: 18,
                        AppAsset.icClose,
                        color: AppColor.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Obx(
            () => isLoading.value
                ? const Expanded(child: ReportBottomSheetShimmerUi())
                : Expanded(
                    child: SingleChildScrollView(
                      child: ListView.builder(
                        itemCount: reportTypes.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => selectedReportType.value = index,
                            child: Container(
                              height: 46,
                              color: AppColor.transparent,
                              padding: const EdgeInsets.only(left: 15),
                              child: Row(
                                children: [
                                  Obx(
                                    () => ReportRadioButtonUi(
                                      isSelected: selectedReportType.value == index,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    reportTypes[index].title ?? "",
                                    style: AppFontStyle.styleW500(AppColor.black, 16),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
          Obx(
            () => Visibility(
              visible: !isLoading.value,
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColor.colorTabBar.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          'Cancelar',
                          style: AppFontStyle.styleW700(AppColor.colorTabBar, 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    GestureDetector(
                      onTap: _sendReport,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: AppColor.primaryLinearGradient,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          'Reportar',
                          style: AppFontStyle.styleW700(AppColor.white, 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReportRadioButtonUi extends StatelessWidget {
  const ReportRadioButtonUi({super.key, required this.isSelected});
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      color: AppColor.transparent,
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? null : AppColor.transparent,
              gradient: isSelected ? AppColor.primaryLinearGradient : null,
            ),
            child: Container(
              height: 20,
              width: 20,
              margin: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? null : AppColor.colorGreyBg,
                border: Border.all(
                  color: isSelected ? AppColor.white : AppColor.primary.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showReportBottomSheet({
  required BuildContext context,
  required String eventId,
  required int eventType,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColor.transparent,
    builder: (context) => ReportBottomSheetUi(
      eventId: eventId,
      eventType: eventType,
    ),
  );
}
