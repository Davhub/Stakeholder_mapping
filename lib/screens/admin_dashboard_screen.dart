import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mapping/component/component.dart';
import 'package:mapping/screens/screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String selectedLGA = '';
  String selectedWard = '';
  String adminState = '';

  Map<String, List<String>> lgaMap = {};
  Map<String, List<String>> wardMap = {};

  final List<String> states = ['Lagos', 'Oyo'];
  final List<String> countries = ['Nigeria'];

  var holder;

  @override
  void initState() {
    super.initState();
    _initializeLGAsAndWards(); // Initialize LGAs and Wards as maps
    _getAdminState();
  }

  // Initialize the maps for LGAs and wards
  void _initializeLGAsAndWards() {
    lgaMap = {
      'Lagos': [
        'Agege',
        'Ajeromi-Ifelodun',
        'Alimosho',
        'Amuwo-Odofin',
        'Apapa',
        'Badagry',
        'Epe',
        'Eti-Osa',
        'Ibeju-Lekki',
        'Ifako-Ijaiye',
        'Ikeja',
        'Ikorodu',
        'Kosofe',
        'Lagos Island',
        'Lagos Mainland',
        'Mushin',
        'Ojo',
        'Oshodi-Isolo',
        'Somolu',
        'Surulere',
      ],
      'Oyo': [
        'Afijio',
        'Akinyele',
        'Atiba',
        'Atisbo',
        'Egbeda',
        'Ibadan North',
        'Ibadan North-East',
        'Ibadan North-West',
        'Ibadan South-East',
        'Ibadan South-West',
        'Ibarapa Central',
        'Ibarapa East',
        'Ibarapa North',
        'Ido LGA',
        'Irepo',
        'Iseyin',
        'Itesiwaju',
        'Iwajowa',
        'Kajola',
        'Lagelu',
        'Ogbomosho North',
        'Ogbomosho South',
        'Ogo Oluwa',
        'Olorunsogo',
        'Oluyole',
        'Ona-Ara',
        'Orelope',
        'Ori-Ire',
        'Oyo East',
        'Oyo West',
        'Saki East',
        'Saki West',
        'Surulere (Oyo)',
      ]
    };

    wardMap = {
      'Agege': [
        'Isale-Oja/Idi-Mangoro',
        'Iloro/Onipetesi',
        'Oniwaya/Papauku',
        'Agbotikuyo/Dopemu',
        'Okekoto',
        'Keke',
        'Darocha',
        'Tabon-Tabon/Oko-Oba',
      ],
      'Ajeromi-Ifelodun': [
        'Awodi-Ora',
        'Ojo Road',
        'Layeni',
        'Alaba Oro',
        'Mosafejo',
        'Ago Hausa',
        'Wilmer',
        'Olodi',
        'Tolu',
        'Temidire I',
      ],
      'Alimosho': [
        'Shasha/Akowonjo',
        'Egbeda/Alimosho',
        'Ipaja North',
        'Ipaja South',
        'Ayobo/Ijon',
        'Oke-Odo/Pleasure',
        'Abule-Egba/Alagbado',
        'Idimu/Isheri',
        'Ikotun/Ijegun',
        'Egbe/Agodo',
        'Igando/Egan',
      ],
      'Amuwo-Odofin': [
        'Amuwo Odofin Housing Estate',
        'Festac I',
        'Festac II',
        'Festac III',
        'Kirikiri',
        'Satellite',
        'Agboju',
        'Ijegun',
        'Iyagbe',
        'Ibeshe',
        'Igbologun',
      ],
      'Apapa': [
        'Apapa I',
        'Apapa II',
        'Apapa III',
        'Apapa IV',
        'Afolabi Alasia Street',
        'Ijora-Oloye',
        'Gaskiya',
        'Iganmu',
        'Malu Road',
      ],
      'Badagry': [
        'Posukoh',
        'Awhanjigoh',
        'Apa Group',
        'Keta-East Group',
        'Iworo-Gbanko Group',
        'Ajido Group',
        'Ibereko Group',
        'Araromi/Ilogbo Group',
        'Ikoga Group',
        'Ajara Group',
        'Iyafin Group',
      ],
      'Epe': [
        'Ajaganabe',
        'Etita Ebode',
        'Ise/Igbogun',
        'Lagbade',
        'Oke-Balogun',
        'Popo-Oba',
        'Oriba/Ladaba',
        'Abomiti',
        'Agbowa',
        'Agbowa-Ikosi',
        'Ago-owu',
        'Ejirin',
        'Ibonwon',
        'Ilara',
        'Itoikin',
        'Odomola',
        'Odoragunsin',
        'Orugbo',
        'Poka',
      ],
      'Eti-Osa': [
        'Victoria Island II',
        'Ilasan Housing Estate/Maiyegun',
        'Ikota/Ikate Village',
        'Igbo-Efon/Ikota Housing Estate',
        'Ajah Village',
        'Addo Village',
        'Victoria I',
        'Ikoyi I',
        'Ikoyi II',
        'Obalende',
      ],
      'Ibeju-Lekki': [
        'Ibeju I',
        'Ibeju II',
        'Iwerekun I',
        'Iwerekun II',
        'Lekki I',
        'Lekki II',
        'Orimedu I',
        'Orimedu II',
        'Orimedu III',
        'Siriwon/Igbekodo I',
        'Siriwon/Igbekodo II',
      ],
      'Ifako-Ijaiye': [
        'Fagba/Akute',
        'Iju Isaga',
        'New Ifako/Oyemekun',
        'Old Ifako/Karaole',
        'Obawole',
        'Ogba/Oke-Ira',
        'Alakuko/Kollington',
        'Ijaiye/Agbado',
        'Ijaiye/Ojokoro',
        'Ijegun/Akinade',
        'Pamada/Abule-Egba',
      ],
      'Ikeja': [
        'Airport/Onipetesi/Inilekere',
        'Alausa/Oregun/Olusosun',
        'Anifowoshe/Ikeja',
        'Ipodo/Seriki Aro',
        'Ojodu/Agidingbi/Omole',
        'Adekunle/Adeniyi Jones/Ogba',
        'GRA/Police Barracks',
        'Oke Ira/Aguda',
        'Onigbongbon',
        'Wasimi/Opebi/Allen',
      ],
      'Ikorodu': [
        'Isele I',
        'Isele II',
        'Isele III',
        'Aga/Ijomu',
        'Ipakodo',
        'Isiu',
        'Agura/Iponmi',
        'Odogunyan',
        'Erikorodo',
        'Agbala',
        'Olorunda/Igbala',
        'Imota I',
        'Imota II',
        'Igbogbo I',
        'Igbogbo II',
        'Baiyeku/Oreta',
        'Ibeshe',
        'Ijede I',
        'Ijede II',
      ],
      'Kosofe': [
        'Oworonshoki',
        'Ifako',
        'Anthony/Mende',
        'Ojota/Ogudu',
        'Ketu/Alapere',
        'Ketu/Ikosi',
        'Isheri/Olowo-ira',
        'Agboyi I',
        'Agboyi II',
        'Ajegunle',
      ],
      'Lagos Island': [
        'Olowogbowo/Elegbata',
        'Oluwole',
        'Idumota',
        'Oju –Oto/Isale Eko',
        'Idumagbo/Oko-Awo',
        'Agarawu/Obadina',
        'Iduntafa',
        'Ilupesi',
        'Isale-Agbede',
        'Olosun',
        'Olushi/Kakawa',
        'Popo-Aguda',
        'Anikantamo',
        'Oko- faji',
        'Eiyekole',
        'Onikan/Okesuna',
        'Sandgrouse',
        'Epetedo',
        'Ilubirin/Lafiaji',
      ],
      'Lagos Mainland': [
        'Otto/Iddo',
        'Apapa road and environs',
        'Olaleye village',
        'Makoko/Ebute-Metta,'
            'Oyingbo Market/Ebute-Metta',
        'Glover/Ebute Metta',
        'Oko-Baba',
        'Oyadiran/Estate/Abule-Oja',
        'Alagomeji',
        'Iwaya',
        'Yaba/Igbobi-Sabi',
      ],
      'Mushin': [
        'Alakara',
        'Idi-oro/Odi-olowo',
        'Babalosa',
        'Ojuwoye',
        'Ilupeju',
        'Olateju',
        'Kayode/Fadeyi',
        'Ilupeju/Industrial',
        'Mushin/Atewolara',
        'Papa Ajao',
        'Ilasamaja',
        'Babalosa/Idi-Araba',
        'Itire',
        'Idi-Araba',
      ],
      'Ojo': [
        'Ojo',
        'Okoko',
        'Ajangbadi',
        'Iba',
        'Sabo/Alaba',
        'Ijanikin',
        'Otto/Ilogbo',
        'Irewe',
        'Taffi',
        'Etegbin',
        'Idoluwo',
      ],
      'Oshodi-Isolo': [
        'Oshodi-Bolade',
        'Orile-Oshodi',
        'Mafoluku',
        'Shogunle',
        'Alasia/Shogunle',
        'Isolo',
        'Ajao Estate',
        'Ilasamaja',
        'Okota',
        'Ishagatedo',
        'Oke-Afa/Ejigbo',
      ],
      'Shomolu': [
        'Onipanu',
        'Palm grove/Ijebutedo',
        'Alade',
        'Bajulaiye',
        'Igbobi/Fadeyi',
        'Folagoro/Bajulaiye/Igbari',
        'Mafoloku/Pedro',
        'Bariga',
        'Ilaje/Akoka',
        'Gbagada Phase I/Obanikoro',
        'Gbagada Phase II/Apelehin',
        'Abule Okuta/Ilaje/Bariga',
      ],
      'Surulere': [
        'Akinhanmi/Cole',
        'Yaba/Ojuelegba',
        'Gbaja/Stadium',
        'Shitta/Ogunlana',
        'Adeniran Ogunsanya',
        'Iponrin Housing Estate/Eric Moore',
        'Orile',
        'Coker',
        'Aguda',
        'Ijeshatedo',
        'Itire',
        'Ikate',
      ],

      //oyo lga Wards
      'Afijio': [
        'Ilora I',
        'Ilora II',
        'Ilora III',
        'Fiditi I',
        'Fiditi II',
        'Aawe I',
        'Aawe II',
        'Akinmorin/Jobele',
        'Iware',
        'Imini',
      ],

      'Akinyele': [
        'Ikereku',
        'Olanla/Oboda/Labode',
        'Arulogun/Eniosa/Aroro',
        'Olode/Amosun/Onidundu',
        'Ojo-Emo/Moniya',
        'Akinyele/Isabiyi/Irepodun',
        'Iwokoto/Talonta/Idi-oro',
        'Ojoo/Ajibode/Laniba',
        'Ijaye/Ojedeji',
        'Ajibade/Alabata/Elekuru',
        'Olorisa-Oko/Okegbemi/Mele',
        'Iroko',
      ],

      'Atiba': [
        'Agunpopo I',
        'Agunpopo II',
        'Agunpopo III',
        'Aremo',
        'Ashipa I',
        'Ashipa II',
        'Ashipa III',
        'Bashorun',
        'Oke-afin I',
        'Oke-afin II',
      ],

      'Atisbo': [
        'Ago Are I',
        'Ago Are Ii',
        'Alaga',
        'Basi',
        'Irawo Ile',
        'Irawo Owode',
        'Ofiki',
        'Owo/agunrege/sabe',
        'Tede I',
        'Tede II',
      ],

      'Egbeda': [
        'Ayede/alugbo/koloko',
        'Egbeda',
        'Erunmu',
        'Olodan/ajinogbo',
        'Olode/alakia',
        'Olodo/Kumapayi I',
        'Olodo II',
        'Olodo III',
        'Olubadan Estate',
        'Osegere/awaye',
        'Owobaale/kasumu',
      ],

      'Ibadan North': [
        'Ward I N2',
        'Ward II N3',
        'Ward III N4',
        'Ward IV N5a',
        'Ward V N5b',
        'WARD VI, N6A PART I',
        'WARD VII, N6A PART II',
        'WARD VIII, N6A PART III',
        'WARD IX, N6B PART I',
        'WARD X, N6B PART II',
        'WARD XI, NW8',
        'WARD XII, NW8',
      ],

      'Ibadan North East': [
        'WARD I EI',
        'WARD II NI (PART II)',
        'WARD III E3',
        'WARD IV  E4',
        'WARD V E5A',
        'WARD VI E5B',
        'WARD VII E6',
        'WARD VIII E7 I',
        'WARD IX E7II',
        'WARD X  E8',
        'WARD XI  E9 I',
        'WARD XII  E9 II',
      ],

      'Ibadan North West': [
        'WARD 1 N1 (PART I)',
        'WARD 2 N1 (PART II)',
        'WARD 3 NW1',
        'WARD 4 NW2',
        'WARD 5 NW3 (PART I)',
        'WARD 6 NW3 (PART I)',
        'WARD 7 NW4',
        'WARD 8 NW5',
        'WARD 9 NW6',
        'WARD 10 NW7',
        'WARD 11 NW7',
      ],

      'Ibadan South West': [
        'WARD 1 C2',
        'WARD 2 SW 1',
        'WARD 3 SW2',
        'WARD 4 SW3A & 3B',
        'WARD 5 SW4',
        'WARD 6  SW5',
        'WARD 7  SW6',
        'WARD 8 SW7',
        'WARD 9 SW8 (I)',
        'WARD 10 SW8 II',
        'WARD 11 SW9 (I)',
        'WARD 12 SW9 (II)',
      ],

      'Ibadan South-East': [
        'CI',
        'S 1',
        'S 2A',
        'S 2B',
        'S 3',
        'S 4A',
        'S 4B',
        'S S5',
        'S 6A',
        'S 6B',
        'S 7A',
        'S 7B',
      ],

      'Ibarapa Central': [
        'IDERE I (MOLETE)',
        'IDERE II (OMINIGBO/OKE ‐ OBA)',
        'IDERE III (KOSO/APA)',
        'IBEREKODO I /(PATAOJU)',
        'IBEREKODO/AGBOORO/ITA BAALE',
        'IDOFIN ISAGANUN',
        'IGBOLE/PAKO',
        'ISALE‐OBA',
        'OKESERIN I & II',
        'OKE‐ODO',
      ],

      'Ibarapa East': [
        'OKE ‐OBA',
        'ANKO',
        'ISABA',
        'ABORERIN',
        'NEW ERUWA',
        'SANGO',
        'OKE‐IMALE',
        'ISALE TOGUN',
        'OKE OTUN',
        'ITABO',
      ],

      'Ibarapa North': [
        'AYETE I',
        'AYETE II',
        'IGANGAN I',
        'IGANGAN II',
        'IGANGAN III',
        'IGANGAN IV',
        'OFIKI I',
        'OFIKI II',
        'TAPA I',
        'TAPA II',
      ],

      'Ido': [
        'ABA EMO/ILAJU/ALAKO',
        'AKUFO/IDIGBA/ARAROMI',
        'AKINWARE/AKINDELE',
        'APETE/AYEGUN/AWOTAN',
        'BATAKE/IDI‐IYA',
        'ERINWUSI/KOGUO/ODETOLA',
        'FENWA/OGANLA/ELENUSONSO',
        'IDO/ONIKEDE/OKUNA AWO',
        'OMI ADIO/OMI ONIGBAGBO BAKATARI',
        'OGUNDELE/ALAHO/SIBA/IDI‐AHUN',
      ],

      'Irepo': [
        'AGORO',
        'AJAGUNNA',
        'ATIPA',
        'IBA I',
        'IBA II',
        'IBA III',
        'IBA IV',
        'IBA V',
        'IKOLABA',
        'LAHA/AJANA',
      ],

      'Iseyin': [
        'ADO‐AWAYE',
        'AKINWUMI/OSOOGUN',
        'EKUNLE I',
        'EKUNLE II',
        'FARAMORA',
        'IJEMBA/OKE‐OLA/OKE‐OJA',
        'ISALU I'
            'ISALU II',
        'KOSO I',
        'KOSO II',
        'LADOGAN/OKE EYIN',
      ],

      'Itesiwaju': [
        'BABAODE',
        'IGBOJAIYE',
        'IPAPO',
        'KOMU',
        'OKAKA I',
        'OKAKA II',
        'OKE‐AMU',
        'OTU I',
        'OTU II',
        'OWODE/IPAPO',
      ],

      'Iwajowa': [
        'AGBAAKIN I',
        'AGBAAKIN II',
        'IWERE‐ILE I',
        'IWERE‐ILE II',
        'IWERE‐ILE III',
        'IWERE‐ILE IV',
        'SABI GANA I',
        'SABI GANA II',
        'SABI GANA III',
        'SABI GANA IV',
      ],

      'Kajola': [
        'AYETORO‐OKE I',
        'ELERO',
        'GBELEKALE I & II',
        'IBA‐OGAN',
        'IJO',
        'ILAJI OKE/IWERE‐OKE',
        'IMOBA/OKE‐OGUN',
        'ISEMI‐ILE/IMIA/ILUA',
        'ISIA',
        'KAJOLA',
        'OLELE',
      ],

      'Lagelu': [
        'AJARA/OPEODU',
        'APATERE/KUFFI/OGUNBODE/OGO',
        'ARULOGUN EHIN/KELEBE'
            'EJIOKU/IGBON/ARIKU',
        'LAGELU MARKET/KAJOLA/GBENA',
        'LAGUN',
        'LALUPON I',
        'LALUPON II',
        'LALUPON III',
        'OFA‐IGBO',
        'OGUNJANA/OLOWODE/OGBURO',
        'OGUNREMI/OGUNSINA',
        'OYEDEJI/OLODE/KUTAYI',
        'SAGBE/PABIEKUN',
      ],

      'Ogbomoso North': [
        'ABOGUNDE',
        'AAJE/OGUNBADO',
        'AGUODO/ MASIFA',
        'ISALE AFON',
        'ISALE ALAASA',
        'ISALE ORA/SAJA',
        'JAGUN',
        'OKELERIN',
        'OSUPA',
        'SABO/TARA',
      ],

      'Ogbomoso South': [
        'AKATA',
        'ALAPATA',
        'AROWOMOLE',
        'IBAPON',
        'IJERU I',
        'IJERU II',
        'ILOGBO',
        'ISOKO',
        'LAGBEDU',
        'OKE‐OLA/FARM SETTLEMENT',
      ],

      'Ogo-Oluwa': [
        'AJAAWA I',
        'AJAAWA II',
        'AYEDE',
        'AYETORO',
        'IDEWURE',
        'LAGBEDU',
        'MOWOLOWO/IWO‐ATE',
        'ODO‐OBA',
        'OPETE',
        'OTAMOKUN',
      ],

      'Olorunsogo': [
        'ABOKE (ABOYUN OGUN)',
        'ELERUGBA/ELEHINKE/SAGBO (APERU)',
        'IKOLABA/OBADIMO',
        'ONIGBETI I (IYAMOPO)',
        'ONIGBETI II/SAGBON AGORO (SAGBON)',
        'ONIGBETI III & IV (AGBENI)',
        'OPA/OGUNNIYI',
        'SERIKI I & ABOSINO (OKIN)',
        'SERIKI II (AGBELE)',
        'WARO/APATA‐ALAJE',
      ],

      'Oluyole': [
        'AYEGUN',
        'IDI‐IROKO/IKEREKU',
        'IDI‐OSAN/EGBEDA‐ATUBA',
        'MUSLIM/OGBERE',
        'ODO‐ONA NLA',
        'OKANHINDE/LATUNDE',
        'OLOMI/OLURINDE',
        'OLONDE/ABA‐NLA',
        'ONIPE',
        'ORISUNBARE/OJO‐EKUN',
      ],

      'Ona-Ara': [
        'AKANRAN/OLORUNDA',
        'ARAROMI/APERIN',
        'BADEKU',
        'GBADA EFON',
        'ODI ODEYALE/ODI APERIN',
        'OGBERE',
        'OGBERE TIOYA',
        'OJOKU/AJIA',
        'OLORUNSOGO',
        'OLODE/GBEDUN/OJEBODE',
        'OREMEJI/AGUGU',
      ],

      'Orelope': [
        'Aare',
        'Alepata',
        'Bonni',
        'Igbope/Iyeye I',
        'Igbope/Iyeye II',
        'Igi Isubu',
        'Onibode I',
        'Onibode II',
        'Onibode III',
        'Onigboho/alomo/okere',
      ],

      'Ori Ire': [
        'ORI IRE I',
        'ORI IRE II',
        'ORI IRE III',
        'ORI IRE IV',
        'ORI IRE V',
        'ORI IRE VI',
        'ORI IRE VII',
        'ORI IRE VIII',
        'ORI IRE IX',
        'ORI IRE X',
      ],

      'Oyo East': [
        'AGBOYE/MOLETE',
        'AJAGBA',
        'ALAODI/MODEKE',
        'APAARA',
        'APINNI',
        'BALOGUN',
        'JABATA',
        'OKE APO',
        'OLUAJO',
        'OWODE/ARAROM',
      ],

      'Oyo West': [
        'AKEETAN',
        'AJOKIDERO/AKEWUGBERU',
        'FASOLA/SOKU',
        'ISEKE',
        'ISOKUN I',
        'ISOKUN II',
        'IYAJI',
        'OPAPA',
        'OWODE',
        'PAKOYI/IDODE',
      ],

      'Saki East': [
        'AGBONLE',
        'AGO AMODU I',
        'AGO AMODU II',
        'OGBOORO I',
        'OGBOORO II',
        'OJE OWODE I',
        'OJE OWODE II',
        'SEPETERI I',
        'SEPETERI II',
        'SEPETERI III',
        'SEPETERI IV',
      ],

      'Saki West': [
        'AGANMU/KOOKO',
        'AJEGUNLE',
        'BAGII',
        'EKOKAN / IMUA',
        'IYA',
        'OGIDIGBO/KINNIKINNI',
        'OKE‐ORO',
        'OKERE I',
        'OKERE II',
        'SANGOTE/BOODA/BAABO/ILUA',
        'SEPETERI/BAPON',
      ],

      'Surulere (Oyo)': [
        'BAYA‐OJE',
        'IGBON/GAMBARI',
        'IRESAAPA',
        'AROLU',
        'IRESAADU',
        'IREGBA',
        'IWOFIN',
        'OKO',
        'ILAJUE',
        'MAYIN',
      ],
    };
  }

  // Fetch admin's state from Firestore
  Future<void> _getAdminState() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          adminState = userDoc['state'] ?? '';
          selectedLGA = '';
          selectedWard = '';
        });
      }
    }
  }

  // Handle LGA selection
  void _onLGAChanged(String? lga) {
    setState(() {
      selectedLGA = lga ?? '';
      selectedWard = '';
    });
  }

  // Reset filters for LGA and Ward
  void _resetFilter() {
    setState(() {
      selectedLGA = '';
      selectedWard = '';
    });
  }

  // Stream to fetch filtered stakeholders based on LGA and Ward
  Stream<QuerySnapshot> _getFilteredStakeholders() {
    CollectionReference stakeholders =
        FirebaseFirestore.instance.collection('stakeholders');
    Query query = stakeholders.where('state', isEqualTo: adminState);

    if (selectedLGA.isNotEmpty) {
      query = query.where('lg', isEqualTo: selectedLGA);
    }
    if (selectedWard.isNotEmpty) {
      query = query.where('ward', isEqualTo: selectedWard);
    }

    return query.snapshots();
  }

  void _deleteStakeholder(String stakeholderId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text(
                'Delete Stakeholder',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete this stakeholder? This action cannot be undone.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('stakeholders')
                    .doc(stakeholderId)
                    .delete();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Stakeholder deleted successfully!'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _editStakeholder(
      String stakeholderId, Map<String, dynamic> stakeholderData) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditStakeholderScreen(
          stakeholderId: stakeholderId,
          stakeholderData: stakeholderData,
          data: {},
        ),
      ),
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const AuthScreen(),
      ),
    );
  }

  void _addStakeholder() {
    final adminId = FirebaseAuth.instance.currentUser?.uid ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddStakeholderScreen(adminId: adminId),
      ),
    );
    _scaffoldKey.currentState
        ?.openEndDrawer(); // Close the drawer after navigation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$adminState Admin Dashboard',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _addStakeholder,
            icon: const Icon(Icons.person_add),
            tooltip: 'Add Stakeholder',
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text(
                      'Logout Confirmation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: const Text('Are you sure you want to logout?'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filter Section Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.filter_list,
                            color: Colors.deepPurple,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Filter Stakeholders',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // LGA Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedLGA.isEmpty ? null : selectedLGA,
                      items: (lgaMap[adminState] ?? []).map((String lga) {
                        return DropdownMenuItem<String>(
                          value: lga,
                          child: Text(lga),
                        );
                      }).toList(),
                      hint: const Text('Select Local Government'),
                      onChanged: _onLGAChanged,
                      decoration: InputDecoration(
                        labelText: 'Local Government Area',
                        prefixIcon: const Icon(Icons.location_city, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.deepPurple,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Ward Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedWard.isEmpty ? null : selectedWard,
                      items: (wardMap[selectedLGA] ?? []).map((String ward) {
                        return DropdownMenuItem<String>(
                          value: ward,
                          child: Text(ward),
                        );
                      }).toList(),
                      hint: const Text('Select Ward'),
                      onChanged: (ward) =>
                          setState(() => selectedWard = ward ?? ''),
                      decoration: InputDecoration(
                        labelText: 'Ward',
                        prefixIcon: const Icon(Icons.map, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.deepPurple,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Reset Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _resetFilter,
                        icon: const Icon(Icons.clear_all, size: 20),
                        label: const Text(
                          'Reset Filters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stakeholders List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getFilteredStakeholders(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.deepPurple,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  }

                  final stakeholders = snapshot.data!.docs;

                  if (stakeholders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.deepPurple.shade300,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No Stakeholders Found',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Try adjusting your filters or add new stakeholders',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: stakeholders.length,
                    itemBuilder: (context, index) {
                      final stakeholder =
                          stakeholders[index].data() as Map<String, dynamic>;
                      final stakeholderName =
                          stakeholder['fullName'] ?? 'No Name';
                      final stakeholderId = stakeholders[index].id;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    AdminStakeholderViewScreen(
                                  stakeholder: stakeholder,
                                  stakeholderId: stakeholderId,
                                  stakeholderData: stakeholder,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.deepPurple.shade300,
                                        Colors.deepPurple.shade600
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      stakeholderName.isNotEmpty
                                          ? stakeholderName[0].toUpperCase()
                                          : 'S',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        stakeholderName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on_rounded,
                                              size: 14,
                                              color: Colors.grey[500]),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              '${stakeholder['lg'] ?? 'No LGA'}, ${stakeholder['ward'] ?? 'Ward'}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.business,
                                              size: 14,
                                              color: Colors.grey[500]),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              stakeholder['association'] ??
                                                  'No Association',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert,
                                      color: Colors.grey[600]),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  onSelected: (value) {
                                    if (value == 'Edit') {
                                      _editStakeholder(
                                          stakeholderId, stakeholder);
                                    } else if (value == 'Delete') {
                                      _deleteStakeholder(stakeholderId);
                                    }
                                  },
                                  itemBuilder: (BuildContext context) =>
                                      <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'Edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit,
                                              size: 20, color: Colors.blue),
                                          SizedBox(width: 12),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'Delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete,
                                              size: 20, color: Colors.red),
                                          SizedBox(width: 12),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
