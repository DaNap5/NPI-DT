import 'package:flutter/material.dart';

import 'package:npi/miscellaneous/service_options.dart';
import 'package:npi/miscellaneous/service_option.dart';
import 'package:npi/miscellaneous/widgets/service_card.dart';
import 'package:npi/miscellaneous/widgets/service_details_dialog.dart';
import 'package:npi/miscellaneous/widgets/header.dart';

class MiscellaneousPage extends StatefulWidget {
  const MiscellaneousPage({super.key});

  @override
  State<MiscellaneousPage> createState() => _MiscellaneousPageState();
}

class _MiscellaneousPageState extends State<MiscellaneousPage> {
  // Controlador del buscador
  final TextEditingController _searchController = TextEditingController();

  // Texto introducido en el buscador
  String _searchQuery = '';

  // Servicios filtrados
  List<ServiceOption> get filteredOptions {
    return serviceOptions.where((service) {
      return service.titulo.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Mostrar información del servicio
  void _showServiceDetails(ServiceOption service) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return ServiceDetailsDialog(service: service);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<ServiceOption> opciones = filteredOptions;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      // APP BAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Otros servicios',
          style: TextStyle(
            color: Color(0xFF263238),
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF263238)),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Header(
                searchController: _searchController,
                searchQuery: _searchQuery,
                onSearchChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                onClearSearch: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              ),
              const SizedBox(height: 16),

              // GRILLA DE SERVICIOS
              Expanded(
                child: opciones.isEmpty
                    ? const Center(
                        child: Text(
                          'No se encontraron servicios.',
                          style: TextStyle(fontSize: 15, color: Colors.grey),
                        ),
                      )
                    : GridView.builder(
                        itemCount: opciones.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15,
                              childAspectRatio: 0.95, // A mayor número, más bajo será el botón
                            ),
                        itemBuilder: (context, index) {
                          final service = opciones[index];

                          return ServiceCard(
                            service: service,
                            onTap: () {
                              _showServiceDetails(service);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
