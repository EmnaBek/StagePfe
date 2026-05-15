import 'package:flutter/material.dart';

import 'package:interface_stage/app/routes.dart';
import 'package:interface_stage/core/session/user_session.dart';
import 'package:interface_stage/core/widgets/connection_banner.dart';
import 'package:interface_stage/core/widgets/dashboard_tile.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _DashboardHeader(),
              const SizedBox(height: 24),
              ValueListenableBuilder<String?>(
                valueListenable: UserSession.authToken,
                builder: (context, authToken, child) {
                  return ConnectionBanner(
                    connected: authToken != null && authToken.trim().isNotEmpty,
                  );
                },
              ),
              const SizedBox(height: 24),
              ValueListenableBuilder<String?>(
                valueListenable: UserSession.displayName,
                builder: (context, displayName, child) {
                  final String name = displayName?.trim().isNotEmpty == true
                      ? displayName!.trim()
                      : 'Utilisateur';

                  return Text(
                    'Bienvenue, $name',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Choisissez un service pour continuer.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.05,
                children: [
                  DashboardTile(
                    icon: Icons.point_of_sale,
                    title: 'Caisse',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.caisse),
                  ),
                  DashboardTile(
                    icon: Icons.local_hospital,
                    title: 'Hospitalisation',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.hospitalisation,
                    ),
                  ),
                  DashboardTile(
                    icon: Icons.medical_services,
                    title: 'Prestations',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.prestations,
                    ),
                  ),
                  DashboardTile(
                    icon: Icons.verified,
                    title: 'Validation',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.validation,
                    ),
                  ),
                  DashboardTile(
                    icon: Icons.sync,
                    title: 'Référentiel',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.referentiel,
                    ),
                  ),
                  DashboardTile(
                    icon: Icons.support_agent,
                    title: 'Réclamation',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.reclamation,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset(
          'assets/logo_ministere.png',
          height: 48,
        ),
        Image.asset(
          'assets/logo_arch.png',
          height: 48,
        ),
      ],
    );
  }
}
