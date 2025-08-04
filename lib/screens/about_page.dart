import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/app_config.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  // Funções para abrir links externos
  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Não foi possível abrir: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.background,
      body: Stack(
        children: [
          SizedBox(
            height: 198,
            child: Row(
              children: [
                Expanded(child: Image.asset('assets/images/coffee.png', fit: BoxFit.cover)),
                Expanded(child: Image.asset('assets/images/rain.png', fit: BoxFit.cover)),
                Expanded(child: Image.asset('assets/images/forest.png', fit: BoxFit.cover)),
              ],
            ),
          ),

          Positioned(
            top: 136,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(0, 0, 18, 36),
                    Color.fromARGB(255, 17, 23, 27),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 140, left: 24, right: 24, bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Study',
                        style: GoogleFonts.pacifico(
                          color: Colors.white,
                          fontSize: 62,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      TextSpan(
                        text: '.io',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 62,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'O Study.io é mais do que um app: é um companheiro de foco para quem busca estudar com mais concentração e menos estresse.\n\n'
                  '• Interface escura e relaxante, pensada para longas sessões de estudo.\n'
                  '• Sons ambientes como chuva, floresta e cafeteria para imersão total.\n'
                  '• Organize tarefas, registre seu progresso e resuma seus estudos por voz.\n\n'
                  'Este projeto foi desenvolvido com carinho e criatividade como parte de um projeto educacional. Estamos sempre em evolução, assim como o seu aprendizado!',
                  textAlign: TextAlign.left,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 32),
                Wrap(
                  spacing: 12,
                  runSpacing: 3,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _launchURL('https://github.com/Andy-lucas7'),
                      icon: Icon(FontAwesomeIcons.github),
                      label: const Text('GitHub'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 64, 58, 183),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _launchURL('https://www.linkedin.com/in/lucas-andrey7/'),
                      icon: Icon(FontAwesomeIcons.linkedin),
                      label: const Text('LinkedIn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 136, 255),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _launchURL('https://forms.gle/JFdV3m73temVruVM9'),
                      icon: const Icon(Icons.feedback),
                      label: const Text('Enviar feedback'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 186, 168),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 34),
                Text('Release 1.0.0',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Desenvolvido com carinho por Lucas Andrey',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top:16,
            left: 12,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Voltar',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
