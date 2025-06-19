import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapping/model/model.dart';
import 'package:url_launcher/url_launcher.dart'; // Import the url_launcher package

class StakeholderView extends StatelessWidget {
  const StakeholderView({super.key, required this.holder});

  final Stakeholder holder;

  // Function to launch the phone dialer
  void _launchDialer(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffe9f7fc),
        title: Padding(
          padding: const EdgeInsets.only(left: 45),
          child: Text(
            'Stakeholder Details',
            style: GoogleFonts.montserrat(
              textStyle: const TextStyle(
                fontSize: 20,
              ),
            ),
          ),
        ),
      ),
      //AppBar ends here

      //body starts here
      body: Stack(
        children: [
          Column(
            children: [
              //First Section picture box container
              Container(
                height: 290,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xffe9f7fc),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 35),
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          maxRadius: 70,
                          child: Image.asset('assets/avatar.png'),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              //fist section picture box container ends here

              //second section plain background
              Expanded(
                child: Container(color: Colors.white54),
              ),
              //section ends her (plain background )
            ],
          ),

          //position for elevated card

          Positioned(
            top: 200, // Slightly above the bottom of the first section
            left: 20,
            right: 20,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(
                  Radius.circular(15),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //Row First: Name
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 20.0, left: 20, top: 10),
                      child: Row(
                        children: [
                          const Text(
                            'Name:',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            holder.fullName,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),

                    //Row Two: Phone number (Clickable)
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 20.0, left: 20, top: 10),
                      child: Row(
                        children: [
                          const Text(
                            'Phone Number:',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(width: 5),
                          GestureDetector(
                            onTap: () => _launchDialer(
                                holder.phoneNumber), // Launch phone dialer
                            child: Text(
                              holder.phoneNumber,
                              style: const TextStyle(
                                fontSize: 16, // Underline for better UX
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),

                    //Row Three: Whatsapp number
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 20.0, left: 20, top: 10),
                      child: Row(
                        children: [
                          const Text(
                            'Whatsapp Number:',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            holder.whatsappNumber,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),

                    //Row four: Email section
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 20.0, left: 20, top: 10),
                      child: Row(
                        children: [
                          const Text(
                            'Email:',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            holder.email,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),

                    //Row Five: State section
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 20.0, left: 20, top: 10),
                      child: Row(
                        children: [
                          const Text(
                            'State:',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            holder.state,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),

                    //Row Six: local government Section
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 20.0, left: 20, top: 10),
                      child: Row(
                        children: [
                          const Text(
                            'Local Government:',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            holder.lg,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),

                    //Row Seven: Ward section
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 20.0, left: 20, top: 10),
                      child: Row(
                        children: [
                          const Text(
                            'Ward:',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            holder.ward,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),

                    //Row Eight: Level of Administration Section
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 20.0, left: 20, top: 10),
                      child: Row(
                        children: [
                          const Text(
                            'Level of Administration:',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            holder.levelOfAdministration,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.visible,
                          ),
                        ],
                      ),
                    ),
                    const Divider(),

                    //Row Nine: Assocaition Section

                    Padding(
                      padding: const EdgeInsets.only(
                        right: 20.0,
                        left: 20,
                        top: 10,
                        bottom: 10,
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Association:',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Expanded(
                            child: Text(
                              holder.association,
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.visible,
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          //position for elevated card ends here
        ],
      ),
    );
  }
}
