import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'input_formatters.dart';
import '../services/cep_service.dart';

class CepEnderecoField extends StatefulWidget {
  final TextEditingController cepController;
  final TextEditingController enderecoController;
  final TextEditingController? numeroController;
  final String enderecoLabel;
  final String? Function(String?)? enderecoValidator;
  final int enderecoMaxLines;

  const CepEnderecoField({
    super.key,
    required this.cepController,
    required this.enderecoController,
    this.numeroController,
    this.enderecoLabel = 'Endereço',
    this.enderecoValidator,
    this.enderecoMaxLines = 1,
  });

  @override
  State<CepEnderecoField> createState() => _CepEnderecoFieldState();
}

class _CepEnderecoFieldState extends State<CepEnderecoField> {
  bool _consultandoCep = false;
  String? _erroCep;

  Future<void> _consultarCep() async {
    final raw = AppInputFormatters.cepRaw(widget.cepController.text);
    if (raw.length != 8) return;

    setState(() {
      _consultandoCep = true;
      _erroCep = null;
    });

    final result = await CepService.consultar(raw);

    if (!mounted) return;

    setState(() => _consultandoCep = false);

    if (!result.sucesso) {
      setState(() => _erroCep = result.erro);
      return;
    }

    final endereco = result.enderecoCompleto;
    if (endereco.isNotEmpty) {
      widget.enderecoController.text = endereco;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.cepController,
          decoration: InputDecoration(
            labelText: 'CEP',
            prefixIcon: const Icon(Icons.markunread_mailbox_outlined),
            hintText: '00000-000',
            suffixIcon: _consultandoCep
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: 'Buscar endereço',
                    onPressed: _consultarCep,
                  ),
            errorText: _erroCep,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            AppInputFormatters.cep(),
          ],
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Informe o CEP.';
            final raw = AppInputFormatters.cepRaw(value);
            if (raw.length != 8) return 'CEP inválido.';
            return null;
          },
          onChanged: (value) {
            setState(() => _erroCep = null);
            final raw = AppInputFormatters.cepRaw(value);
            if (raw.length == 8) {
              _consultarCep();
            }
          },
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: widget.enderecoController,
                decoration: InputDecoration(
                  labelText: widget.enderecoLabel,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: widget.enderecoMaxLines,
                validator: widget.enderecoValidator,
              ),
            ),
            if (widget.numeroController != null) ...[
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: widget.numeroController,
                  decoration: const InputDecoration(
                    labelText: 'Número',
                    prefixIcon: Icon(Icons.numbers_outlined),
                  ),
                  keyboardType: TextInputType.text,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
