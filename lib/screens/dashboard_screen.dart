import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mapping/component/component.dart';
import 'package:mapping/model/model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Box<Stakeholder>? stakeholderBox;
  List<Stakeholder> allStakeholders = [];
  List<Stakeholder> filteredStakeholders = [];
  bool isLoading = true;
  String? errorMessage;
  StreamSubscription? firestoreSubscription;

  String? currentUserState;
  String? selectedLg;
  String? selectedWard;

  List<String> lgs = [];
  List<String> wards = [];

  Map<String, List<String>> lgaMap = {
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
      'Surulere',
    ]
  };

  Map<String, List<String>> wardMap = {
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

    'Surulere': [
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

  @override
  void initState() {
    super.initState();
    fetchCurrentUserState();
  }

  @override
  void dispose() {
    firestoreSubscription?.cancel();
    super.dispose();
  }

  Future<void> fetchCurrentUserState() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (docSnapshot.exists) {
          currentUserState = docSnapshot.data()?['state'] as String?;
          if (currentUserState != null) {
            setFirestoreListener();
          } else {
            setState(() {
              isLoading = false;
              errorMessage = 'State not found for the current user.';
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching user state: $e';
      });
    }
  }

  Future<void> initializeData() async {
    try {
      stakeholderBox = await Hive.openBox<Stakeholder>('stakeholderBox');
      if (stakeholderBox!.isNotEmpty) {
        allStakeholders = stakeholderBox!.values.toList();
        setState(() {
          filteredStakeholders = allStakeholders;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load data: $e';
      });
    }
  }

  void setFirestoreListener() {
    firestoreSubscription = FirebaseFirestore.instance
        .collection('stakeholders')
        .where('state', isEqualTo: currentUserState)
        .snapshots()
        .listen((snapshot) async {
      List<Stakeholder> fetchedStakeholders = snapshot.docs
          .map((doc) => Stakeholder.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();

      await stakeholderBox?.clear();
      await stakeholderBox?.addAll(fetchedStakeholders);

      setState(() {
        allStakeholders = fetchedStakeholders;
        filteredStakeholders = allStakeholders;
        updateLgsAndWards();
        isLoading = false;
      });

      print('Hive data updated from Firestore in real time.');
    }, onError: (error) {
      print('Error listening to Firestore updates: $error');
    });
  }

  void updateLgsAndWards() {
    setState(() {
      lgs = currentUserState != null && lgaMap.containsKey(currentUserState!)
          ? lgaMap[currentUserState!]!
          : [];
      if (selectedLg != null && !lgs.contains(selectedLg)) {
        selectedLg = null;
      }

      wards = selectedLg != null && wardMap.containsKey(selectedLg!)
          ? wardMap[selectedLg!]!
          : [];
      if (selectedWard != null && !wards.contains(selectedWard)) {
        selectedWard = null;
      }
    });
  }

  void filterStakeholders() {
    setState(() {
      filteredStakeholders = allStakeholders.where((stakeholder) {
        final matchesLg = selectedLg == null || stakeholder.lg == selectedLg;
        final matchesWard =
            selectedWard == null || stakeholder.ward == selectedWard;
        return matchesLg && matchesWard;
      }).toList();
    });
  }

  void resetFilter() {
    setState(() {
      selectedLg = null;
      selectedWard = null;
      filteredStakeholders = allStakeholders;
      wards.clear();
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const AuthScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffe9f7fc),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$currentUserState State StakeHolders'),
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text(
                        'Are you sure you want to logout?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: _logout,
                          child: const Text(
                            'Yes',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(errorMessage!),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: fetchCurrentUserState,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedLg,
                                hint: const Text('Select LGA'),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                items: lgs.map((lg) {
                                  return DropdownMenuItem(
                                    value: lg,
                                    child: Text(
                                      lg,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedLg = value;
                                    updateLgsAndWards();
                                    filterStakeholders();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedWard,
                                hint: const Text('Select Ward'),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                items: wards.map((ward) {
                                  return DropdownMenuItem(
                                    value: ward,
                                    child: Text(
                                      ward,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedWard = value;
                                    filterStakeholders();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: resetFilter,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue),
                            child: const Text(
                              'Reset Filter',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        //lsit of stakeholders
                        Expanded(
                          child: filteredStakeholders.isEmpty
                              ? const Center(
                                  child: Text('No Stakeholders Found'))
                              : ListView.builder(
                                  itemCount: filteredStakeholders.length,
                                  itemBuilder: (context, index) {
                                    final stakeholder =
                                        filteredStakeholders[index];
                                    return StakeHolderCard(holder: stakeholder);
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
