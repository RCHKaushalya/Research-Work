# Localization Strings for Employee Management System

STRINGS = {
    'si': {
        'title': 'සේවක කළමනාකරණ පද්ධතිය',
        'subtitle': 'විශාල රැකියා සඳහා ඩෙස්ක්ටොප් ද්වාරය',
        'nic_hint': 'NIC අංකය ඇතුළත් කරන්න',
        'pin_hint': 'PIN අංකය ඇතුළත් කරන්න',
        'login_btn': 'පාලක පුවරුවට පිවිසෙන්න',
        'logout': 'පිටවෙන්න',
        'main_title': 'මගේ රැකියා',
        'post_job': 'අලුත් රැකියාවක් පල කරන්න',
        'refresh': 'යාවත්කාලීන කරන්න',
        'col_title': 'මාතෘකාව',
        'col_area': 'ප්‍රදේශය',
        'col_workers': 'සේවකයින්',
        'col_status': 'තත්ත්වය',
        'col_actions': 'ක්‍රියාමාර්ග',
        'manage': 'කළමනාකරණය',
        'back': 'ආපසු',
        'job_details': 'රැකියා විස්තර',
        'applicants': 'අයදුම්කරුවන්',
        'assign': 'පත් කරන්න',
        'msg': 'පණිවිඩ',
        'group': 'කණ්ඩායම්',
        'salary': 'වැටුප් කළමනාකරණය',
        'task': 'පැවරුම්',
        'error': 'දෝෂයකි',
        'success': 'සාර්ථකයි',
        'lang_switch': 'Tamil',
        'description': 'විස්තරය',
        'skills_req': 'අවශ්‍ය කුසලතා',
        'public_profile': 'පොදු පැතිකඩ',
        'bio': 'ජීව දත්ත',
        'review': 'සමාලෝචනය',
        'give_review': 'සමාලෝචනයක් ලබා දෙන්න',
        'total_salary': 'මුළු වැටුප',
        'paid': 'ගෙවා ඇත',
        'pending': 'ඉතිරි',
        'create_group': 'කණ්ඩායමක් සාදන්න'
    },
    'ta': {
        'title': 'பணியாளர் மேலாண்மை அமைப்பு',
        'subtitle': 'பெரிய வேலைகளுக்கான டெஸ்க்டாப் போர்டல்',
        'nic_hint': 'NIC எண்ணை உள்ளிடவும்',
        'pin_hint': 'PIN எண்ணை உள்ளிடவும்',
        'login_btn': 'டாஷ்போர்டிற்கு உள்நுழையவும்',
        'logout': 'வெளியேறு',
        'main_title': 'எனது வேலைகள்',
        'post_job': 'புதிய வேலையை இடுங்கள்',
        'refresh': 'புதுப்பிக்கவும்',
        'col_title': 'தலைப்பு',
        'col_area': 'பகுதி',
        'col_workers': 'பணியாளர்கள்',
        'col_status': 'நிலை',
        'col_actions': 'நடவடிக்கைகள்',
        'manage': 'நிர்வகி',
        'back': 'பின்னால்',
        'job_details': 'வேலை விவரங்கள்',
        'applicants': 'விண்ணப்பதாரர்கள்',
        'assign': 'ஒதுக்கு',
        'msg': 'செய்திகள்',
        'group': 'குழுக்கள்',
        'salary': 'சம்பள மேலாண்மை',
        'task': 'பணிகள்',
        'error': 'பிழை',
        'success': 'வெற்றி',
        'lang_switch': 'Sinhala',
        'description': 'விளக்கம்',
        'skills_req': 'தேவையான திறன்கள்',
        'public_profile': 'பொது சுயவிவரம்',
        'bio': 'சுயசரிதை',
        'review': 'மதிப்பாய்வு',
        'give_review': 'மதிப்பாய்வு கொடுங்கள்',
        'total_salary': 'மொத்த சம்பளம்',
        'paid': 'செலுத்தப்பட்டது',
        'pending': 'நிலுவையில் உள்ளது',
        'create_group': 'குழுவை உருவாக்கு'
    }
}

class LanguageProvider:
    def __init__(self):
        self.current = 'si'
    
    def toggle(self):
        self.current = 'ta' if self.current == 'si' else 'si'
    
    def t(self, key):
        return STRINGS[self.current].get(key, key)
