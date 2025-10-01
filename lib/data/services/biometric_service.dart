import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import './storage_service.dart';

class BiometricService extends GetxService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final StorageService _storage = Get.find<StorageService>();
  final RxBool isBiometricAvailable = false.obs;
  final RxBool isBiometricEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkBiometricAvailability();
    _loadBiometricPreference();
  }

  Future<BiometricService> init() async {
    await _checkBiometricAvailability();
    await _loadBiometricPreference();
    return this;
  }

  Future<void> _loadBiometricPreference() async {
    try {
      final preference = await _storage.getBiometricPreference();
      isBiometricEnabled.value = preference;
    } catch (e) {
      isBiometricEnabled.value = false;
    }
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      isBiometricAvailable.value = isAvailable && isDeviceSupported;
      if (isBiometricAvailable.value) {
        await _checkBiometricTypes();
      }
    } catch (e) {
      isBiometricAvailable.value = false;
    }
  }

  Future<void> _checkBiometricTypes() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      final hasFingerprint = availableBiometrics.contains(BiometricType.fingerprint) ||
          availableBiometrics.contains(BiometricType.strong) ||
          availableBiometrics.contains(BiometricType.face) ||
          availableBiometrics.contains(BiometricType.weak);
      if (hasFingerprint) {
        isBiometricEnabled.value = true;
      }
    } catch (e) {
      isBiometricEnabled.value = false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      if (!isBiometricAvailable.value) {
        Get.snackbar('Biometria não disponível', 'Seu dispositivo não suporta autenticação biométrica', snackPosition: SnackPosition.BOTTOM);
        return false;
      }
      if (!isBiometricEnabled.value) {
        Get.snackbar('Biometria desabilitada', 'Ative a biometria nas configurações para usar esta funcionalidade', snackPosition: SnackPosition.BOTTOM);
        return false;
      }
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Autentique-se para entrar',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Autenticação biométrica',
            cancelButton: 'Cancelar',
          ),
          IOSAuthMessages(
            cancelButton: 'Cancelar',
          ),
        ],
      );
      return isAuthenticated;
    } on PlatformException catch (e) {
      String errorMessage = 'Erro na autenticação biométrica';
      switch (e.code) {
        case 'NotAvailable':
          errorMessage = 'Biometria não disponível';
          break;
        case 'NotEnrolled':
          errorMessage = 'Nenhuma biometria cadastrada';
          break;
        case 'PasscodeNotSet':
          errorMessage = 'Configure um PIN ou senha no dispositivo';
          break;
        case 'LockedOut':
          errorMessage = 'Muitas tentativas. Tente novamente mais tarde';
          break;
        case 'UserCancel':
          errorMessage = 'Autenticação cancelada';
          break;
        default:
          errorMessage = 'Erro: ${e.message}';
      }
      Get.snackbar('Erro', errorMessage, snackPosition: SnackPosition.BOTTOM);
      return false;
    } catch (e) {
      Get.snackbar('Erro', 'Erro inesperado na autenticação biométrica', snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  Future<bool> canUseBiometrics() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!canCheckBiometrics || !isDeviceSupported) {
        return false;
      }
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> toggleBiometric(bool enabled) async {
    try {
      isBiometricEnabled.value = enabled;
      await _storage.saveBiometricPreference(enabled);
    } catch (e) {
      isBiometricEnabled.value = !enabled;
      Get.snackbar('Erro', 'Não foi possível salvar a configuração de biometria', snackPosition: SnackPosition.BOTTOM);
    }
  }
}


