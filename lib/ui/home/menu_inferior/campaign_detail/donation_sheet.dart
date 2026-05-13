part of 'campaign_detail_page.dart';

// Página completa para hacer donación
class _DonationPage extends StatelessWidget {
  const _DonationPage({
    required this.detail,
    required this.campaignService,
  });

  final CampaignDetail detail;
  final CampaignService campaignService;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Solo permitir volver con el botón de back si el usuario lo presiona intencionalmente
      onWillPop: () async {
        // Permitir que se cierre, pero esto previene cierres accidentales por gestos
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.bluePrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Hacer Donación',
          style: TextStyle(
            color: AppColors.bluePrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        ),
        body: _DonationSheet(
          detail: detail,
          campaignService: campaignService,
        ),
      ),
    );
  }
}

// Widget interno con el formulario
class _DonationSheet extends StatefulWidget {
  const _DonationSheet({
    required this.detail,
    required this.campaignService,
  });

  final CampaignDetail detail;
  final CampaignService campaignService;

  @override
  State<_DonationSheet> createState() => _DonationSheetState();
}

class _DonationSheetState extends State<_DonationSheet> {
  static const int _maxReceiptSizeInBytes = 5 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String _method = 'qr';
  String? _selectedRewardId;
  bool _rewardSelectionTouched = false;
  bool _anonymous = false;
  bool _submitting = false;
  bool _isPickingReceipt = false;
  String? _errorMessage;
  String? _receiptError;
  Uint8List? _receiptBytes;
  XFile? _receiptFile;
  
  // Control de monto máximo permitido
  double? _maxAllowedAmount;
  bool _loadingMaxAmount = true;

  CampaignPaymentInstructions get _paymentInstructions => widget.detail.paymentInstructions;

  bool get _hasReceipt => _receiptBytes != null && _receiptBytes!.isNotEmpty;

  List<double> get _suggestedAmounts {
    final suggestions = <double>{};
    for (final reward in widget.detail.rewards) {
      if (reward.minimumDonation > 0) {
        suggestions.add(reward.minimumDonation);
      }
      if (suggestions.length >= 3) {
        break;
      }
    }
    if (suggestions.isEmpty) {
      suggestions.addAll(const [50, 100, 200]);
    }
    final ordered = suggestions.toList()..sort();
    return ordered;
  }

  @override
  void initState() {
    super.initState();
    _loadMaxAllowedAmount();
  }

  /// Carga el monto máximo permitido para esta campaña
  Future<void> _loadMaxAllowedAmount() async {
    try {
      final response = await Supabase.instance.client
          .rpc('get_campaign_max_donation_amount', params: {
        'p_campaign_id': widget.detail.summary.id,
      }).select();

      if (response != null && response.isNotEmpty) {
        final data = response.first as Map<String, dynamic>;
        final maxAmount = data['max_amount'];
        
        setState(() {
          _maxAllowedAmount = maxAmount != null ? (maxAmount as num).toDouble() : null;
          _loadingMaxAmount = false;
        });
      } else {
        setState(() {
          _loadingMaxAmount = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando monto máximo: $e');
      setState(() {
        _loadingMaxAmount = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final summary = widget.detail.summary;
    final methodInstructionWidgets = _buildMethodInstructionWidgets(context);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: bottomInset + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Header con gradiente
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.bluePrimary.withValues(alpha: 0.08),
                      AppColors.greenSuccess.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.bluePrimary.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Icono corazón grande
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.bluePrimary,
                            AppColors.greenSuccess,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.bluePrimary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Apoya esta campaña',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkText,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      summary.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.bluePrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.bluePrimary.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people_outline,
                            size: 18,
                            color: AppColors.bluePrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Únete a los donadores',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.bluePrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              
              // Sección de monto
              Text(
                '💰 ¿Cuánto quieres aportar?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
              ),
              const SizedBox(height: 16),
              
              // Montos sugeridos - Chips modernos
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _suggestedAmounts.map((amount) {
                  final isSelected = _amountController.text == _formatPlainAmount(amount);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _amountController.text = _formatPlainAmount(amount);
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  AppColors.bluePrimary,
                                  AppColors.bluePrimary.withValues(alpha: 0.8),
                                ],
                              )
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.bluePrimary
                              : AppColors.grayNeutral.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.bluePrimary.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Bs.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isSelected ? Colors.white : AppColors.darkText.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatPlainAmount(amount),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: isSelected ? Colors.white : AppColors.darkText,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              // Input de monto personalizado
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                decoration: InputDecoration(
                  labelText: 'Monto personalizado',
                  prefixIcon: const Icon(Icons.attach_money_outlined, size: 28),
                  hintText: '0.00',
                  suffixText: 'Bs.',
                  suffixStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.bluePrimary,
                        fontWeight: FontWeight.w700,
                      ),
                  filled: true,
                  fillColor: AppColors.grayNeutral.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.grayNeutral.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.grayNeutral.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.bluePrimary,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  final amount = _parseAmount(value ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Ingresa un monto válido';
                  }
                  
                  // Validar que no exceda el monto máximo disponible
                  if (_maxAllowedAmount != null && _maxAllowedAmount! > 0) {
                    if (amount > _maxAllowedAmount!) {
                      return 'Máximo: Bs. ${_formatPlainAmount(_maxAllowedAmount!)} (meta casi alcanzada)';
                    }
                  }
                  
                  return null;
                },
              ),
              
              // Mensaje informativo del monto restante
              if (!_loadingMaxAmount && _maxAllowedAmount != null && _maxAllowedAmount! > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.orangeAction.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.orangeAction.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: AppColors.orangeAction.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '¡Cerca de la meta! Solo faltan Bs. ${_formatPlainAmount(_maxAllowedAmount!)} para completarla.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.orangeAction.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Método de pago
              Text(
                '💳 ¿Cómo realizaste el pago?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
              ),
              const SizedBox(height: 16),
              
              // Tarjetas de métodos de pago
              Column(
                children: [
                  _buildPaymentMethodCard(
                    context: context,
                    method: 'qr',
                    icon: Icons.qr_code_2,
                    title: 'Pago con QR',
                    subtitle: 'Escaneaste el código QR',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentMethodCard(
                    context: context,
                    method: 'transferencia',
                    icon: Icons.account_balance,
                    title: 'Transferencia bancaria',
                    subtitle: 'Realizaste una transferencia',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentMethodCard(
                    context: context,
                    method: 'otro',
                    icon: Icons.more_horiz,
                    title: 'Otro método',
                    subtitle: 'Coordinado con el organizador',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                    ),
                  ),
                ],
              ),
              ...methodInstructionWidgets,
              if (widget.detail.rewards.isNotEmpty) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  value: _selectedRewardId,
                  decoration: const InputDecoration(
                    labelText: 'Recompensa a reclamar (opcional)',
                    prefixIcon: Icon(Icons.card_giftcard_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No reclamar recompensa'),
                    ),
                    ...widget.detail.rewards.map(
                      (reward) => DropdownMenuItem<String?>(
                        value: reward.id,
                        child: Text(
                          '${reward.title} · mín. Bs. ${_formatPlainAmount(reward.minimumDonation)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _rewardSelectionTouched = true;
                      _selectedRewardId = value;
                    });
                  },
                ),
              ],
              const SizedBox(height: 24),
              _buildReceiptPicker(context),
              const SizedBox(height: 20),
              TextFormField(
                controller: _messageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mensaje para el equipo (opcional)',
                  alignLabelWithHint: true,
                  helperText: 'Comparte información adicional o unas palabras de aliento para el organizador.',
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _anonymous,
                onChanged: (value) => setState(() => _anonymous = value ?? false),
                title: const Text('Quiero aparecer como donación anónima'),
                subtitle: const Text('Tu aporte cuenta igual y solo el equipo organizador conocerá tus datos.'),
              ),
              const SizedBox(height: 12),
              Text(
                'Todas las donaciones se revisan manualmente para garantizar transparencia. Te avisaremos cuando el equipo las apruebe.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.darkText.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
              ),
              // Mensaje de error mejorado
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.orangeAction.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.orangeAction.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.orangeAction.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline,
                          color: AppColors.orangeAction,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.orangeAction,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              
              // Botón de confirmación mejorado
              Container(
                width: double.infinity,
                height: 58,
                decoration: BoxDecoration(
                  gradient: _submitting
                      ? null
                      : const LinearGradient(
                          colors: [
                            AppColors.bluePrimary,
                            Color(0xFF4CAF50),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _submitting
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.bluePrimary.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _submitting ? null : _submit,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _submitting
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Registrando donación...',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Confirmar donación',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final amount = _parseAmount(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Ingresa un monto válido');
      return;
    }

    if (_receiptError != null) {
      setState(() => _errorMessage = _receiptError);
      return;
    }

    if (!_hasReceipt) {
      setState(() => _errorMessage = 'Adjunta la foto del comprobante para continuar.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    var resolvedRewardId = _selectedRewardId;
    if (resolvedRewardId == null && !_rewardSelectionTouched) {
      resolvedRewardId = _resolveEligibleReward(amount);
    }

    try {
      await widget.campaignService.createDonation(
        campaignId: widget.detail.summary.id,
        amount: amount,
        method: _method,
        message: _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
        anonymous: _anonymous,
        rewardId: resolvedRewardId,
        receiptBytes: _receiptBytes,
        receiptFileName: _receiptFile?.name,
      );

      if (!mounted) {
        return;
      }
      
      // Mostrar mensaje simple de éxito
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.greenSuccess,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  '¡Donación registrada!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Será revisada por el equipo',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
      
      // Auto-cerrar después de 2 segundos
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      
      // Cerrar el diálogo y la página
      Navigator.of(context, rootNavigator: true).pop(); // Cierra diálogo
      Navigator.of(context).pop(true); // Cierra página donación
      
    } on CampaignServiceException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      debugPrint('DonationSheet.submit error: $error');
      setState(() {
        _submitting = false;
        _errorMessage = 'No pudimos registrar tu donación. Intenta nuevamente.';
      });
    }
  }

  double? _parseAmount(String input) {
    final sanitized = input.replaceAll(RegExp(r'[^0-9,\.]'), '').replaceAll(',', '.');
    return double.tryParse(sanitized);
  }

  String _formatPlainAmount(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

  List<Widget> _buildMethodInstructionWidgets(BuildContext context) {
    final instructions = _paymentInstructions;
    if (instructions.isEmpty) {
      return const [];
    }

    List<Widget> content;
    switch (_method) {
      case 'qr':
        if (!instructions.hasQr) {
          content = [
            _buildInfoMessage(
              context: context,
              icon: Icons.qr_code_2_outlined,
              title: 'QR no disponible',
              message: 'El organizador todavía no configuró un código QR. Usa transferencia u otro método y adjunta tu comprobante.',
            ),
          ];
        } else {
          content = [
            Text(
              'Escanea este código QR desde tu app bancaria',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
            ),
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: () => _showQrPreview(instructions.qrUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    instructions.qrUrl!,
                    height: 180,
                    width: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        width: 180,
                        alignment: Alignment.center,
                        color: AppColors.grayNeutral.withValues(alpha: 0.12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.broken_image_outlined, color: AppColors.orangeAction),
                            const SizedBox(height: 6),
                            Text(
                              'No pudimos cargar el QR',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.darkText.withValues(alpha: 0.7),
                                  ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: () => unawaited(_downloadQr(instructions.qrUrl!)),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Descargar'),
                ),
              ],
            ),
          ];
        }
        break;
      case 'transferencia':
        if (!instructions.hasBankDetails) {
          content = [
            _buildInfoMessage(
              context: context,
              icon: Icons.account_balance_outlined,
              title: 'Datos bancarios pendientes',
              message: 'El organizador compartirá los datos bancarios pronto. Adjunta tu comprobante para que podamos validar tu aporte.',
            ),
          ];
        } else {
          final detailTiles = <Widget>[];
          if (instructions.bankHolder?.trim().isNotEmpty == true) {
            detailTiles.add(_buildBankDetailTile(context, 'Titular', instructions.bankHolder!.trim()));
          }
          if (instructions.bankName?.trim().isNotEmpty == true) {
            detailTiles.add(_buildBankDetailTile(context, 'Banco', instructions.bankName!.trim()));
          }
          if (instructions.bankAccountType?.trim().isNotEmpty == true) {
            detailTiles.add(_buildBankDetailTile(context, 'Tipo de cuenta', instructions.bankAccountType!.trim()));
          }
          if (instructions.bankAccountNumber?.trim().isNotEmpty == true) {
            detailTiles.add(_buildBankDetailTile(context, 'Número de cuenta', instructions.bankAccountNumber!.trim()));
          }

          if (detailTiles.isEmpty) {
            content = [
              _buildInfoMessage(
                context: context,
                icon: Icons.account_balance_outlined,
                title: 'Datos bancarios pendientes',
                message: 'El organizador compartirá los datos bancarios pronto. Adjunta tu comprobante para que podamos validar tu aporte.',
              ),
            ];
          } else {
            content = [
              Text(
                'Datos para transferencia',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
              ),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < detailTiles.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      detailTiles[i],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Una vez realizada la transferencia, adjunta el comprobante para agilizar la validación manual.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.darkText.withValues(alpha: 0.65),
                      height: 1.35,
                    ),
              ),
            ];
          }
        }
        break;
      default:
        // En campañas anónimas no exponemos el teléfono del organizador al público.
        final isAnonymous = widget.detail.summary.isAnonymous;
        final phone = isAnonymous ? null : widget.detail.organizerContactPhone;
        final hasPhone = phone?.trim().isNotEmpty == true;
        content = [
          _buildInfoMessage(
            context: context,
            icon: Icons.handshake_outlined,
            title: 'Coordina el método alternativo',
            message: hasPhone
                ? 'Contacta al organizador al ${phone!.trim()} para coordinar la entrega o método alternativo. Adjunta la foto del comprobante para validar tu donación.'
                : 'Coordina con el equipo de la campaña por los canales habituales y adjunta la foto del comprobante para validar tu donación.',
            action: hasPhone
                ? TextButton.icon(
                    onPressed: () => unawaited(_copyToClipboard(phone!.trim(), 'Número copiado al portapapeles')),
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Copiar número'),
                  )
                : null,
          ),
        ];
    }

    if (content.isEmpty) {
      return const [];
    }

    return [
      const SizedBox(height: 16),
      ...content,
    ];
  }

  Widget _buildBankDetailTile(BuildContext context, String label, String value) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.darkText.withValues(alpha: 0.6),
            ),
      ),
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.copy_outlined),
        onPressed: () => unawaited(_copyToClipboard(value, '$label copiado al portapapeles')),
      ),
      onTap: () => unawaited(_copyToClipboard(value, '$label copiado al portapapeles')),
    );
  }

  Widget _buildInfoMessage({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grayNeutral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.bluePrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkText,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.darkText.withValues(alpha: 0.7),
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            action,
          ],
        ],
      ),
    );
  }

  Widget _buildReceiptPicker(BuildContext context) {
    final theme = Theme.of(context);

    if (_hasReceipt) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.greenSuccess, Color(0xFF4CAF50)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✅ Comprobante adjunto',
                      style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.greenSuccess,
                          ),
                    ),
                    Text(
                      'Verifica que sea legible',
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.darkText.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Preview del comprobante con marco profesional
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    _receiptBytes!,
                    width: double.infinity,
                    height: 240,
                    fit: BoxFit.cover,
                  ),
                ),
                // Overlay con botones
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      _buildIconButton(
                        icon: Icons.image_outlined,
                        onPressed: _submitting || _isPickingReceipt ? null : _pickReceipt,
                        tooltip: 'Cambiar',
                      ),
                      const SizedBox(width: 8),
                      _buildIconButton(
                        icon: Icons.delete_outline,
                        onPressed: _submitting ? null : _removeReceipt,
                        tooltip: 'Quitar',
                        color: AppColors.orangeAction,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.insert_drive_file_outlined,
                size: 16,
                color: AppColors.bluePrimary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _receiptFile?.name ?? 'comprobante.jpg',
                  style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.darkText.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (_receiptError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.orangeAction.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.orangeAction,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _receiptError!,
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.orangeAction,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📎 Comprobante de pago',
          style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
        ),
        const SizedBox(height: 12),
        
        // Card de upload mejorada
        GestureDetector(
          onTap: _submitting || _isPickingReceipt ? null : _pickReceipt,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.bluePrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.bluePrimary.withValues(alpha: 0.2),
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isPickingReceipt)
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.bluePrimary),
                    ),
                  )
                else
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.bluePrimary,
                          Color(0xFF4CAF50),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.bluePrimary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.cloud_upload_outlined,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  _isPickingReceipt ? 'Abriendo galería...' : 'Toca para seleccionar imagen',
                  style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.bluePrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'El comprobante es obligatorio para validar tu donación',
                  style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.darkText.withValues(alpha: 0.6),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'JPG, PNG, WEBP · Máx 5 MB',
                    style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.darkText.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_receiptError != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.orangeAction.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.orangeAction,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _receiptError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.orangeAction,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickReceipt() async {
    if (_isPickingReceipt || _submitting) {
      return;
    }

    setState(() {
      _isPickingReceipt = true;
      _receiptError = null;
    });

    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2048,
      );
      if (picked == null) {
        return;
      }

      final bytes = await picked.readAsBytes();
      if (bytes.lengthInBytes > _maxReceiptSizeInBytes) {
        if (!mounted) {
          return;
        }
        setState(() {
          _receiptBytes = null;
          _receiptFile = null;
          _receiptError = 'El comprobante debe pesar menos de 5 MB.';
        });
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _receiptBytes = bytes;
        _receiptFile = picked;
        _receiptError = null;
      });
    } on PlatformException catch (error) {
      debugPrint('DonationSheet._pickReceipt platform error: $error');
      if (!mounted) {
        return;
      }
      setState(() {
        _receiptError = 'No pudimos acceder a la galería. Revisa los permisos.';
      });
    } catch (error) {
      debugPrint('DonationSheet._pickReceipt unexpected error: $error');
      if (!mounted) {
        return;
      }
      setState(() {
        _receiptError = 'No pudimos cargar el comprobante. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() => _isPickingReceipt = false);
      }
    }
  }

  void _removeReceipt() {
    setState(() {
      _receiptBytes = null;
      _receiptFile = null;
      _receiptError = null;
    });
  }

  Future<void> _showQrPreview(String url) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 5,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (imageContext, error, stackTrace) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.broken_image_outlined, color: AppColors.orangeAction, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'No pudimos abrir el QR en este momento.',
                        textAlign: TextAlign.center,
                        style: Theme.of(dialogContext).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadQr(String imageUrl) async {
    if (!mounted) return;
    
    // Guardar referencia al BuildContext actual antes de operaciones async
    final downloadContext = context;
    
    // Mostrar diálogo de carga
    showDialog(
      context: downloadContext,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false, // Prevenir cierre con botón back
        child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.bluePrimary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
              SizedBox(height: 20),
              Text(
                'Descargando QR...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
    
    try {

      debugPrint('🔵 Iniciando descarga de QR: $imageUrl');
      
      // Descargar la imagen
      final response = await http.get(Uri.parse(imageUrl));
      debugPrint('🔵 Respuesta HTTP: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        throw Exception('Error al descargar la imagen');
      }

      // Usar SaverGallery con manejo de errores
      final fileName = 'QR_Donacion_${DateTime.now().millisecondsSinceEpoch}';
      
      debugPrint('🔵 Guardando imagen con SaverGallery...');
      
      final result = await SaverGallery.saveImage(
        Uint8List.fromList(response.bodyBytes),
        quality: 100,
        fileName: fileName,
        androidRelativePath: "Pictures/ManossolidariasQR",
        skipIfExists: false,
      );
      
      debugPrint('🔵 Resultado: ${result.isSuccess}');
      if (!result.isSuccess) {
        debugPrint('� Error: ${result.errorMessage}');
      }

      if (!mounted) return;

      // Cerrar el diálogo de carga usando el contexto correcto
      Navigator.of(downloadContext, rootNavigator: true).pop();
      
      // Pequeña espera para asegurar que el diálogo se cerró
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;

      if (result.isSuccess) {
        // Mostrar diálogo de éxito (NO dismissible para evitar cierres accidentales)
        showDialog(
          context: downloadContext,
          barrierDismissible: false,
          builder: (successDialogContext) => WillPopScope(
            onWillPop: () async => false, // Prevenir cierre con botón back
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.greenSuccess,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '¡QR guardado en Galería!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Búscalo en Pictures/ManossolidariasQR',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            ),
          ),
        );
        
        // Esperar 2 segundos y cerrar automáticamente el diálogo de éxito
        await Future.delayed(const Duration(seconds: 2));
        
        if (!mounted) return;
        
        // Cerrar solo el diálogo de éxito, no la página
        Navigator.of(downloadContext, rootNavigator: true).pop();
      } else {
        throw Exception(result.errorMessage ?? 'Error desconocido');
      }
    } catch (error) {
      debugPrint('Error descargando QR: $error');
      if (!mounted) return;
      
      // Cerrar el diálogo de carga
      Navigator.of(downloadContext, rootNavigator: true).pop();
      
      // Pequeña espera para asegurar que el diálogo se cerró
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;
      
      // Mostrar diálogo de error (NO dismissible)
      showDialog(
        context: downloadContext,
        barrierDismissible: false,
        builder: (errorDialogContext) => WillPopScope(
          onWillPop: () async => false, // Prevenir cierre con botón back
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.orangeAction,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'No se pudo descargar el QR',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Intenta nuevamente',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            ),
          ),
        ),
      );
      
      // Esperar 2 segundos y cerrar automáticamente el diálogo de error
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      
      // Cerrar solo el diálogo de error, no la página
      Navigator.of(downloadContext, rootNavigator: true).pop();
    }
  }

  Future<void> _openLinkExternally(String rawUrl) async {
    final trimmed = rawUrl.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El enlace no es válido.')),
      );
      return;
    }

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos abrir el enlace.')),
        );
      }
    } catch (error) {
      debugPrint('DonationSheet._openLinkExternally error: $error');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocurrió un problema al abrir el enlace.')),
      );
    }
  }

  Future<void> _copyToClipboard(String value, String feedback) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(feedback)),
    );
  }

  String? _resolveEligibleReward(double amount) {
    if (widget.detail.rewards.isEmpty) {
      return null;
    }

    final eligible = widget.detail.rewards.where((reward) {
      if (amount < reward.minimumDonation) {
        return false;
      }
      final remaining = reward.availableQuantity;
      if (reward.isLimited && remaining != null && remaining <= 0) {
        return false;
      }
      return true;
    }).toList();

    if (eligible.isEmpty) {
      return null;
    }

    eligible.sort((a, b) => a.minimumDonation.compareTo(b.minimumDonation));
    return eligible.last.id;
  }

  Widget _buildPaymentMethodCard({
    required BuildContext context,
    required String method,
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
  }) {
    final isSelected = _method == method;
    
    return GestureDetector(
      onTap: () {
        setState(() => _method = method);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.bluePrimary
                : AppColors.grayNeutral.withValues(alpha: 0.2),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.bluePrimary.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Icono con gradiente
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: isSelected ? gradient : null,
                color: isSelected ? null : AppColors.grayNeutral.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.darkText.withValues(alpha: 0.4),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.bluePrimary : AppColors.darkText,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.darkText.withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            ),
            // Check icon
            if (isSelected)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.bluePrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
    Color color = Colors.white,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color == Colors.white
              ? Colors.white.withValues(alpha: 0.95)
              : color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(20),
            child: Icon(
              icon,
              size: 20,
              color: color == Colors.white ? AppColors.darkText : color,
            ),
          ),
        ),
      ),
    );
  }
}
