import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class CabezeraTest extends StatefulWidget {
  final String version;
  final String codigo;
  final String fecha;
  final String numeroPrueba;


  const CabezeraTest({
    Key? key,
    required this.numeroPrueba,
    required this.version,
    required this.codigo,
    required this.fecha,
  }) : super(key: key);

  @override
  State<CabezeraTest> createState() => _CabezeraTestState();
}

class _CabezeraTestState extends State<CabezeraTest> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.assignment_outlined,color: AppColors.primary,size: 25,),
                    SizedBox(width: 10,),
                    Text('Información de la Prueba',style: AppTextStyles.titleBoldBlack,)
                  ],
                ),
                Text('Datos importados desde Odoo (solo lectura)',style: AppTextStyles.subTitleGrey)
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(label: "Versión", value: widget.version),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _InfoItem(label: "Código", value: widget.codigo),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Segunda fila (Fecha - Resultado)
            Row(
              children: [
                Expanded(
                  child: _InfoItem(label: "Fecha", value: widget.fecha),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _InfoItem(label: "Número de prueba", value: widget.numeroPrueba),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}


