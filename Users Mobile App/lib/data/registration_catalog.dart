class RegistrationOption {
  const RegistrationOption({
    required this.id,
    required this.englishName,
    required this.sinhalaName,
    required this.tamilName,
    required this.icon,
  });

  final String id;
  final String englishName;
  final String sinhalaName;
  final String tamilName;
  final String icon;

  String labelFor(String languageCode) {
    switch (languageCode) {
      case 'si':
        return sinhalaName;
      case 'ta':
        return tamilName;
      default:
        return englishName;
    }
  }
}

class RegistrationCatalog {
  static const List<RegistrationOption> jobCategories = [
    RegistrationOption(id: 'C01', englishName: 'Construction & Technical', sinhalaName: 'ඉදිකිරීම් සහ කාර්මික', tamilName: 'நிர்மாணம் மற்றும் தொழிநுட்பம்', icon: '🏗️'),
    RegistrationOption(id: 'C02', englishName: 'Transport & Delivery', sinhalaName: 'ප්රවාහන සහ බෙදාහැරීම්', tamilName: 'போக்குவரத்து மற்றும் விநியோகம்', icon: '🚛'),
    RegistrationOption(id: 'C03', englishName: 'Agriculture & Plantation', sinhalaName: 'කෘෂිකර්මය සහ වතු', tamilName: 'விவசாயம் மற்றும் தோட்டம்', icon: '🌱'),
    RegistrationOption(id: 'C04', englishName: 'Home & Cleaning', sinhalaName: 'නිවාස සහ පිරිසිදු කිරීම්', tamilName: 'வீடு மற்றும் சுத்தம் செய்தல்', icon: '🧹'),
    RegistrationOption(id: 'C05', englishName: 'Technical Repair', sinhalaName: 'තාක්ෂණික සහ අලුත්වැඩියා', tamilName: 'தொழில்நுட்ப மற்றும் பழுதுபார்ப்பு', icon: '🔧'),
    RegistrationOption(id: 'C06', englishName: 'Food & Tourism', sinhalaName: 'ආහාර සහ සංචාරක', tamilName: 'உணவு மற்றும் சுற்றுலா', icon: '👨‍🍳'),
    RegistrationOption(id: 'C07', englishName: 'Beauty & Fashion', sinhalaName: 'රූපලාවන්ය සහ විලාසිතා', tamilName: 'அழகு மற்றும் ஃபேஷன்', icon: '✂️'),
    RegistrationOption(id: 'C08', englishName: 'Arts & Crafts', sinhalaName: 'කලා සහ අත්කම්', tamilName: 'கலை மற்றும் கைவினை', icon: '🎨'),
    RegistrationOption(id: 'C09', englishName: 'Security & Operations', sinhalaName: 'ආරක්ෂක සහ මෙහෙයුම්', tamilName: 'பாதுகாப்பு மற்றும் செயல்பாடுகள்', icon: '🛡️'),
    RegistrationOption(id: 'C10', englishName: 'General Trade', sinhalaName: 'සාමාන්ය වෙළඳාම', tamilName: 'பொது வர்த்தகம்', icon: '🛍️'),
    RegistrationOption(id: 'C11', englishName: 'Fishing & Aquaculture', sinhalaName: 'ධීවර සහ ජලජ', tamilName: 'மீன்பிடி மற்றும் நீர்வாழ்', icon: '🎣'),
    RegistrationOption(id: 'C12', englishName: 'IT & Clerical', sinhalaName: 'තොරතුරු තාක්ෂණ සහ ලිපිකරු', tamilName: 'தகவல் தொழில்நுட்பம் மற்றும் எழுத்தர்', icon: '💻'),
    RegistrationOption(id: 'C13', englishName: 'Events & Catering', sinhalaName: 'උත්සව සහ සැපයුම්', tamilName: 'நிகழ்வுகள் மற்றும் கேட்டரிங்', icon: '🎊'),
    RegistrationOption(id: 'C14', englishName: 'Health & Care', sinhalaName: 'සෞඛ්‍ය සහ රැකවරණ', tamilName: 'சுகாதாரம் மற்றும் பராமரிப்பு', icon: '🏥'),
  ];

  static const Map<String, List<RegistrationOption>> skillsByCategory = {
    'C01': [
      RegistrationOption(id: 'S101', englishName: 'Mason', sinhalaName: 'මේසන් බාස්', tamilName: 'மேசன் பாஸ்', icon: '🧱'),
      RegistrationOption(id: 'S102', englishName: 'Carpentry', sinhalaName: 'වඩු වැඩ', tamilName: 'தச்சு வேலை', icon: '🔨'),
      RegistrationOption(id: 'S103', englishName: 'Welding', sinhalaName: 'වෙල්ඩින් වැඩ', tamilName: 'வெல்டிங் வேலை', icon: '⚡'),
    ],
    'C02': [
      RegistrationOption(id: 'S201', englishName: 'Three Wheeler Driver', sinhalaName: 'ත්රීරෝද රථ රියදුරු', tamilName: 'த்ரிவீலர் ஓட்டுநர்', icon: '🛺'),
      RegistrationOption(id: 'S202', englishName: 'Heavy Vehicle Driver', sinhalaName: 'බර වාහන රියදුරු', tamilName: 'கனரக வாகன ஓட்டுநர்', icon: '🚛'),
      RegistrationOption(id: 'S203', englishName: 'Delivery Rider', sinhalaName: 'ඩිලිවරි රයිඩර්', tamilName: 'டெலிவரி ரைடர்', icon: '🛵'),
    ],
    'C03': [
      RegistrationOption(id: 'S301', englishName: 'Paddy Farming', sinhalaName: 'වී ගොවිතැන', tamilName: 'நெல் விவசாயம்', icon: '🌾'),
      RegistrationOption(id: 'S302', englishName: 'Vegetable / Fruit Farming', sinhalaName: 'එළවළු/පළතුරු වගාව', tamilName: 'காய்கறி/பழ வளர்ப்பு', icon: '🍎'),
      RegistrationOption(id: 'S303', englishName: 'Tea / Rubber Plucking', sinhalaName: 'තේ/රබර් නෙලීම', tamilName: 'தேயிலை/රப்பர் பறித்தல்', icon: '🍃'),
    ],
    'C04': [
      RegistrationOption(id: 'S401', englishName: 'House Helper', sinhalaName: 'ගෘහ සේවක/සේවිකා', tamilName: 'வீட்டு உதவியாளர்', icon: '🏠'),
      RegistrationOption(id: 'S402', englishName: 'Cleaning', sinhalaName: 'පිරිසිදු කිරීම්', tamilName: 'சுத்தம் செய்தல்', icon: '🧹'),
      RegistrationOption(id: 'S403', englishName: 'Gardener', sinhalaName: 'උයන්පල්ලා', tamilName: 'தோட்டக்காரர்', icon: '🌳'),
    ],
    'C05': [
      RegistrationOption(id: 'S501', englishName: 'Electrician', sinhalaName: 'විදුලි කාර්මික', tamilName: 'மின்சார வல்லுநர்', icon: '💡'),
      RegistrationOption(id: 'S502', englishName: 'Plumber', sinhalaName: 'නල කාර්මික', tamilName: 'குழாய் பழுதுபார்ப்பவர்', icon: '🚰'),
      RegistrationOption(id: 'S503', englishName: 'Mechanic', sinhalaName: 'මෝටර් රථ මිකැනික්', tamilName: 'மோட்டார் மெக்கானிக்', icon: '🏎️'),
    ],
    'C06': [
      RegistrationOption(id: 'S601', englishName: 'Cook', sinhalaName: 'කෝකියා', tamilName: 'சமையல்காரர்', icon: '👨‍🍳'),
      RegistrationOption(id: 'S602', englishName: 'Tour Guide', sinhalaName: 'සංචාරක මගපෙන්වන්නන්', tamilName: 'சுற்றுலா வழிகாட்டி', icon: '🗺️'),
      RegistrationOption(id: 'S603', englishName: 'Waiter', sinhalaName: 'වේටර්', tamilName: 'உதவியாளர்', icon: '🍽️'),
    ],
    'C07': [
      RegistrationOption(id: 'S701', englishName: 'Barber', sinhalaName: 'බාබර්', tamilName: 'பார்பர்', icon: '💈'),
      RegistrationOption(id: 'S702', englishName: 'Beautician', sinhalaName: 'රූපලාවන්ය ශිල්පී', tamilName: 'அழகுக்கலை நிபுணர்', icon: '💅'),
      RegistrationOption(id: 'S703', englishName: 'Tailor', sinhalaName: 'ඇඳුම් මැසීම', tamilName: 'தையல் காரர்', icon: '🧵'),
    ],
    'C08': [
      RegistrationOption(id: 'S801', englishName: 'Photographer', sinhalaName: 'ඡායාරූප ශිල්පී', tamilName: 'புகைப்படக் கலைஞர்', icon: '📸'),
      RegistrationOption(id: 'S802', englishName: 'Musician / Dancer', sinhalaName: 'සංගීත/නර්තන ශිල්පීන්', tamilName: 'இசை/நடனக் கலைஞர்', icon: '💃'),
      RegistrationOption(id: 'S803', englishName: 'Pottery', sinhalaName: 'කලල/මැටි නිර්මාණ', tamilName: 'மட்பாண்டக் கலை', icon: '🏺'),
    ],
    'C09': [
      RegistrationOption(id: 'S901', englishName: 'Security Officer', sinhalaName: 'ආරක්ෂක නිලධාරී', tamilName: 'பாதுகாப்பு அதிகாரி', icon: '🛡️'),
      RegistrationOption(id: 'S902', englishName: 'Night Guard', sinhalaName: 'රාත්‍රී මුරකරු', tamilName: 'இரவு காவலாளி', icon: '🔦'),
    ],
    'C10': [
      RegistrationOption(id: 'S1001', englishName: 'Street Vendor', sinhalaName: 'වීදි වෙළෙන්දා', tamilName: 'தெரு வியாபாரி', icon: '🧺'),
      RegistrationOption(id: 'S1002', englishName: 'Mobile Vendor', sinhalaName: 'ජංගම වෙළෙන්දා', tamilName: 'நடமாடும் வியாபாரி', icon: '🚐'),
      RegistrationOption(id: 'S1003', englishName: 'Shop Owner', sinhalaName: 'කුඩා කඩ හිමිකරු', tamilName: 'சிறு கடை உரிமையாளர்', icon: '🏪'),
    ],
    'C11': [
      RegistrationOption(id: 'S1101', englishName: 'Sea Fisher', sinhalaName: 'මුහුදු ධීවර', tamilName: 'கடல் மீன்பிடி', icon: '⛵'),
      RegistrationOption(id: 'S1102', englishName: 'Dried Fish Production', sinhalaName: 'කරවල නිෂ්පාදනය', tamilName: 'கருவாடு உற்பத்தி', icon: '🐟'),
      RegistrationOption(id: 'S1103', englishName: 'Freshwater Fisher', sinhalaName: 'මිරිදිය ධීවර', tamilName: 'நன்னீர் மீன்பிடி', icon: '🛶'),
    ],
    'C12': [
      RegistrationOption(id: 'S1201', englishName: 'Data Entry', sinhalaName: 'දත්ත ඇතුළත් කිරීම', tamilName: 'தரவு உள்ளீடு', icon: '⌨️'),
      RegistrationOption(id: 'S1202', englishName: 'Graphic Design', sinhalaName: 'ග්රැෆික් නිර්මාණ', tamilName: 'கிராஃபிக் வடிவமைப்பு', icon: '🖥️'),
      RegistrationOption(id: 'S1203', englishName: 'Photocopying', sinhalaName: 'පිටපත් කිරීම්', tamilName: 'புகைப்பட நகல்', icon: '📠'),
    ],
    'C13': [
      RegistrationOption(id: 'S1301', englishName: 'Event Decoration', sinhalaName: 'උත්සව සැරසිලි', tamilName: 'நிகழ்வு அலங்காரம்', icon: '🎈'),
      RegistrationOption(id: 'S1302', englishName: 'Catering', sinhalaName: 'කේටරින් සේවා', tamilName: 'கேட்டரிங் சேவைகள்', icon: '🍲'),
      RegistrationOption(id: 'S1303', englishName: 'DJ / Music', sinhalaName: 'ඩීජේ සහ සංගීත', tamilName: 'டிஜே / இசை', icon: '🎧'),
    ],
    'C14': [
      RegistrationOption(id: 'S1401', englishName: 'Patient Care', sinhalaName: 'රෝගී සත්කාරක', tamilName: 'நோயாளி பராமரிப்பு', icon: '🛏️'),
      RegistrationOption(id: 'S1402', englishName: 'Child Care', sinhalaName: 'ළදරු රැකවරණය', tamilName: 'குழந்தை பராமரிப்பு', icon: '👶'),
      RegistrationOption(id: 'S1403', englishName: 'Ayurveda Massage', sinhalaName: 'ආයුර්වේද සම්බාහන', tamilName: 'ஆயுர்வேத மசாஜ்', icon: '💆'),
    ],
  };

  static List<RegistrationOption> skillsForCategories(List<String> categoryIds) {
    final skills = <RegistrationOption>[];
    for (final categoryId in categoryIds) {
      skills.addAll(skillsByCategory[categoryId] ?? const []);
    }
    final unique = <String, RegistrationOption>{};
    for (final skill in skills) {
      unique[skill.id] = skill;
    }
    return unique.values.toList();
  }

  static RegistrationOption? getOptionById(String id) {
    for (var cat in jobCategories) {
      if (cat.id == id) return cat;
    }
    for (var list in skillsByCategory.values) {
      for (var skill in list) {
        if (skill.id == id) return skill;
      }
    }
    return null;
  }
}
