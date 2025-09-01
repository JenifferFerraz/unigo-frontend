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

  /// Inicializa o serviço
  Future<BiometricService> init() async {
    await _checkBiometricAvailability();
    await _loadBiometricPreference();
    return this;
  }

  /// Carrega a preferência de biometria do storage
  Future<void> _loadBiometricPreference() async {
    try {
      final preference = await _storage.getBiometricPreference();
      isBiometricEnabled.value = preference;
    } catch (e) {
      isBiometricEnabled.value = false;
    }
  }

  /// Verifica se a biometria está disponível no dispositivo
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

  /// Verifica os tipos de biometria disponíveis
  Future<void> _checkBiometricTypes() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      // Verifica se há impressão digital disponível
      final hasFingerprint = availableBiometrics.contains(BiometricType.fingerprint);
      
      if (hasFingerprint) {
        isBiometricEnabled.value = true;
      }
    } catch (e) {
      isBiometricEnabled.value = false;
    }
  }

  /// Autentica o usuário usando biometria
  Future<bool> authenticateWithBiometrics() async {
    try {
      if (!isBiometricAvailable.value) {
        Get.snackbar(
          'Biometria não disponível',
          'Seu dispositivo não suporta autenticação biométrica',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      if (!isBiometricEnabled.value) {
        Get.snackbar(
          'Biometria desabilitada',
          'Ative a biometria nas configurações para usar esta funcionalidade',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Toque no sensor de impressão digital para fazer login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      return isAuthenticated;
    } on PlatformException catch (e) {
      String errorMessage = 'Erro na autenticação biométrica';
      
      switch (e.code) {
        case 'NotAvailable':
          errorMessage = 'Biometria não disponível';
          break;
        case 'NotEnrolled':
          errorMessage = 'Nenhuma impressão digital cadastrada';
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
          errorMessage = 'Erro na autenticação: ${e.message}';
      }
      
      Get.snackbar(
        'Erro',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro inesperado na autenticação biométrica',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Verifica se o usuário pode usar biometria
  Future<bool> canUseBiometrics() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (!canCheckBiometrics || !isDeviceSupported) {
        return false;
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.contains(BiometricType.fingerprint);
    } catch (e) {
      return false;
    }
  }

  /// Habilita ou desabilita a biometria
  Future<void> toggleBiometric(bool enabled) async {
    try {
      isBiometricEnabled.value = enabled;
      await _storage.saveBiometricPreference(enabled);
    } catch (e) {
      // Reverte o valor se houver erro ao salvar
      isBiometricEnabled.value = !enabled;
      Get.snackbar(
        'Erro',
        'Não foi possível salvar a configuração de biometria',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
} 