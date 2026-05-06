import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opole/custom/custom_image_picker.dart';
import 'package:opole/ui/image_picker_bottom_sheet_ui.dart';
import 'package:opole/ui/loading_ui.dart';
import 'package:opole/pages/verification_request_page/api/create_verification_request_api.dart';
import 'package:opole/pages/verification_request_page/model/create_verification_request_model.dart';
import 'package:opole/utils/database.dart';
import 'package:opole/utils/enums.dart';
import 'package:opole/utils/utils.dart';

class VerificationRequestController extends GetxController {
  CreateVerificationRequestModel? createVerificationRequestModel;

  String? profileImage;
  String? documentImage;

  TextEditingController idController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  @override
  void onInit() {
    init();
    super.onInit();
  }

  Future<void> init() async {
    idController.clear();
    nameController.clear();
    addressController.clear();

    onCancelProfileImage();
    onCancelDocumentImage();
  }

  Future<void> onSendRequest() async {
    if (profileImage == null) {
      Utils.showToast(EnumLocal.txtPleaseUploadProfileImage.name.tr);
    } else if (documentImage == null) {
      Utils.showToast(EnumLocal.txtPleaseUploadDocumentImage.name.tr);
    } else if (idController.text.trim().isEmpty) {
      Utils.showToast(EnumLocal.txtPleaseEnterYourIdOnNumber.name.tr);
    } else if (nameController.text.trim().isEmpty) {
      Utils.showToast(EnumLocal.txtPleaseEnterYourIdOnName.name.tr);
    } else if (addressController.text.trim().isEmpty) {
      Utils.showToast(EnumLocal.txtPleaseEnterYourIdOnAddress.name.tr);
    } else {
      Utils.showLog("Verification Request Sending....");

      FocusManager.instance.primaryFocus?.unfocus();

      Get.dialog(const LoadingUi(), barrierDismissible: false); // Start Loading...

      createVerificationRequestModel = await CreateVerificationRequestApi.callApi(
        loginUserId: GetStorage().read("loginUserId") ?? "",
        documentId: idController.text,
        nameOnDocument: nameController.text,
        address: idController.text,
        profileSelfie: profileImage ?? "",
        document: documentImage ?? "",
      );

      if (createVerificationRequestModel?.status ?? false) {
        Utils.showToast(EnumLocal.txtVerificationRequestSendSuccessfully.name.tr);
        Get.back();
      } else {
        Utils.showToast(createVerificationRequestModel?.message ?? "");
      }
      Get.back(); // Stop Loading...
    }
  }

  Future<void> onPickProfileImage(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    await ImagePickerBottomSheetUi.show(
      context: context,
      onClickCamera: () async {
        final imagePath = await CustomImagePicker.pickImage(ImageSource.camera);

        if (imagePath != null) {
          profileImage = imagePath;
          update(["onChangeProfileImage"]);
        }
      },
      onClickGallery: () async {
        final imagePath = await CustomImagePicker.pickImage(ImageSource.gallery);

        if (imagePath != null) {
          profileImage = imagePath;
          update(["onChangeProfileImage"]);
        }
      },
    );
  }

  Future<void> onPickDocumentImage(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await ImagePickerBottomSheetUi.show(
      context: context,
      onClickCamera: () async {
        final imagePath = await CustomImagePicker.pickImage(ImageSource.camera);

        if (imagePath != null) {
          documentImage = imagePath;
          update(["onChangeDocumentImage"]);
        }
      },
      onClickGallery: () async {
        final imagePath = await CustomImagePicker.pickImage(ImageSource.gallery);

        if (imagePath != null) {
          documentImage = imagePath;
          update(["onChangeDocumentImage"]);
        }
      },
    );
  }

  Future<void> onCancelProfileImage() async {
    profileImage = null;
    update(["onChangeProfileImage"]);
  }

  Future<void> onCancelDocumentImage() async {
    documentImage = null;
    update(["onChangeDocumentImage"]);
  }
}

