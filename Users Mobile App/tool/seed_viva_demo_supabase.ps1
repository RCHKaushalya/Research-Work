$ErrorActionPreference = 'Stop'

$SupabaseUrl = $env:SUPABASE_URL
if (-not $SupabaseUrl) {
  $SupabaseUrl = 'https://pkzdexdkgjjejctsgnbz.supabase.co'
}

$SupabaseKey = $env:SUPABASE_SERVICE_ROLE_KEY
if (-not $SupabaseKey) {
  $SupabaseKey = $env:SUPABASE_ANON_KEY
}
if (-not $SupabaseKey) {
  $SupabaseKey = 'sb_publishable_m6X8NGNqr0JFKSH5VcV1rw_rtiCKaXt'
}

$headers = @{
  apikey = $SupabaseKey
  Authorization = "Bearer $SupabaseKey"
  'Content-Type' = 'application/json; charset=utf-8'
  Prefer = 'resolution=merge-duplicates,return=minimal'
}

function Upsert-Rows {
  param(
    [Parameter(Mandatory = $true)][string]$Table,
    [Parameter(Mandatory = $true)][array]$Rows,
    [string]$Conflict = ''
  )

  if ($Rows.Count -eq 0) {
    return
  }

  $uri = "$SupabaseUrl/rest/v1/$Table"
  if ($Conflict) {
    $uri = "$uri`?on_conflict=$([uri]::EscapeDataString($Conflict))"
  }

  try {
    Invoke-RestMethod `
      -Method Post `
      -Uri $uri `
      -Headers $headers `
      -Body ($Rows | ConvertTo-Json -Depth 30 -Compress) | Out-Null
    Write-Output "seeded_$Table=$($Rows.Count)"
    return $true
  } catch {
    Write-Warning "failed_$Table=$($_.Exception.Message)"
    return $false
  }
}

function Update-Rows {
  param(
    [Parameter(Mandatory = $true)][string]$Table,
    [Parameter(Mandatory = $true)][string]$Filter,
    [Parameter(Mandatory = $true)][hashtable]$Values
  )

  $uri = "$SupabaseUrl/rest/v1/${Table}?${Filter}"
  $body = $Values | ConvertTo-Json -Depth 20 -Compress

  try {
    Invoke-RestMethod -Method Patch -Uri $uri -Headers $headers -Body $body | Out-Null
    return $true
  } catch {
    Write-Warning "failed_$Table=$($_.Exception.Message)"
    return $false
  }
}

$users = @(
  @{nic='200100000001';first_name='සුනිල්';last_name='පෙරේරා';phone='+94710100001';password_hash='1234';district='01';ds_area='0101';language='si';verified=$true;rating=4.8;completed_jobs_count=34;abandoned_jobs_count=1;posted_jobs_count=2;applied_jobs_count=5;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C01');skill_ids=@('S101','S102','S107');profile_photo_url='https://randomuser.me/api/portraits/men/11.jpg';portfolio_photo_urls=@('https://picsum.photos/seed/workforce-masonry-1/600/400','https://picsum.photos/seed/workforce-masonry-2/600/400')}
  @{nic='200100000002';first_name='නදීෂා';last_name='ප්‍රනාන්දු';phone='+94710100002';password_hash='1234';district='02';ds_area='0205';language='si';verified=$true;rating=4.7;completed_jobs_count=28;abandoned_jobs_count=0;posted_jobs_count=1;applied_jobs_count=7;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C05');skill_ids=@('S501','S502','S505');profile_photo_url='https://randomuser.me/api/portraits/women/12.jpg';portfolio_photo_urls=@('https://picsum.photos/seed/workforce-electric-1/600/400')}
  @{nic='200100000003';first_name='කුමාරි';last_name='ජයසූරිය';phone='+94710100003';password_hash='1234';district='03';ds_area='0308';language='si';verified=$true;rating=4.9;completed_jobs_count=47;abandoned_jobs_count=0;posted_jobs_count=0;applied_jobs_count=9;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C04','C06');skill_ids=@('S401','S402','S403','S601');profile_photo_url='https://randomuser.me/api/portraits/women/13.jpg';portfolio_photo_urls=@('https://picsum.photos/seed/workforce-cleaning-1/600/400')}
  @{nic='200100000004';first_name='රුවන්';last_name='බණ්ඩාර';phone='+94710100004';password_hash='1234';district='04';ds_area='0408';language='si';verified=$true;rating=4.6;completed_jobs_count=39;abandoned_jobs_count=2;posted_jobs_count=1;applied_jobs_count=6;removed_jobs_count=0;availability_status='busy';is_blocked=0;job_category_ids=@('C02');skill_ids=@('S202','S203','S204');profile_photo_url='https://randomuser.me/api/portraits/men/14.jpg'}
  @{nic='200100000005';first_name='සමන්';last_name='හේරත්';phone='+94710100005';password_hash='1234';district='05';ds_area='0505';language='si';verified=$true;rating=4.4;completed_jobs_count=22;abandoned_jobs_count=1;posted_jobs_count=0;applied_jobs_count=4;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C03');skill_ids=@('S301','S302','S303');profile_photo_url='https://randomuser.me/api/portraits/men/15.jpg'}
  @{nic='200100000006';first_name='අනූෂා';last_name='විජේසිංහ';phone='+94710100006';password_hash='1234';district='07';ds_area='0708';language='si';verified=$true;rating=4.9;completed_jobs_count=58;abandoned_jobs_count=0;posted_jobs_count=1;applied_jobs_count=8;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C07');skill_ids=@('S701','S702','S703');profile_photo_url='https://randomuser.me/api/portraits/women/16.jpg'}
  @{nic='200100000007';first_name='චතුර';last_name='සිල්වා';phone='+94710100007';password_hash='1234';district='08';ds_area='0810';language='si';verified=$true;rating=4.5;completed_jobs_count=26;abandoned_jobs_count=0;posted_jobs_count=2;applied_jobs_count=3;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C05');skill_ids=@('S502','S503','S505');profile_photo_url='https://randomuser.me/api/portraits/men/17.jpg'}
  @{nic='200100000008';first_name='මහේෂ්';last_name='ප්‍රියන්ත';phone='+94710100008';password_hash='1234';district='09';ds_area='0904';language='si';verified=$true;rating=4.3;completed_jobs_count=19;abandoned_jobs_count=1;posted_jobs_count=0;applied_jobs_count=5;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C08');skill_ids=@('S801','S802','S803');profile_photo_url='https://randomuser.me/api/portraits/men/18.jpg'}
  @{nic='200100000009';first_name='දිලාන්';last_name='ලක්මාල්';phone='+94710100009';password_hash='1234';district='18';ds_area='1812';language='si';verified=$true;rating=4.2;completed_jobs_count=16;abandoned_jobs_count=0;posted_jobs_count=0;applied_jobs_count=6;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C10');skill_ids=@('S1001','S1002','S1003');profile_photo_url='https://randomuser.me/api/portraits/men/19.jpg'}
  @{nic='200100000010';first_name='හිමාලි';last_name='රණසිංහ';phone='+94710100010';password_hash='1234';district='20';ds_area='2001';language='si';verified=$true;rating=4.6;completed_jobs_count=25;abandoned_jobs_count=0;posted_jobs_count=1;applied_jobs_count=4;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C12');skill_ids=@('S1201','S1202');profile_photo_url='https://randomuser.me/api/portraits/women/20.jpg'}
  @{nic='200100000011';first_name='පවිත්‍රා';last_name='මධුෂානි';phone='+94710100011';password_hash='1234';district='22';ds_area='2201';language='si';verified=$true;rating=4.7;completed_jobs_count=31;abandoned_jobs_count=0;posted_jobs_count=0;applied_jobs_count=6;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C13');skill_ids=@('S1301','S1302');profile_photo_url='https://randomuser.me/api/portraits/women/21.jpg'}
  @{nic='200100000012';first_name='ගයාන්';last_name='සම්පත්';phone='+94710100012';password_hash='1234';district='24';ds_area='2401';language='si';verified=$true;rating=4.1;completed_jobs_count=14;abandoned_jobs_count=1;posted_jobs_count=0;applied_jobs_count=5;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C09');skill_ids=@('S901','S902');profile_photo_url='https://randomuser.me/api/portraits/men/22.jpg'}
  @{nic='200200000001';first_name='அருள்';last_name='குமார்';phone='+94720100001';password_hash='1234';district='10';ds_area='1004';language='ta';verified=$true;rating=4.8;completed_jobs_count=36;abandoned_jobs_count=0;posted_jobs_count=1;applied_jobs_count=8;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C10');skill_ids=@('S1001','S1002');profile_photo_url='https://randomuser.me/api/portraits/men/31.jpg'}
  @{nic='200200000002';first_name='மீனா';last_name='சிவபாலன்';phone='+94720100002';password_hash='1234';district='10';ds_area='1005';language='ta';verified=$true;rating=4.9;completed_jobs_count=44;abandoned_jobs_count=0;posted_jobs_count=0;applied_jobs_count=9;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C07');skill_ids=@('S701','S702','S703');profile_photo_url='https://randomuser.me/api/portraits/women/32.jpg';portfolio_photo_urls=@('https://picsum.photos/seed/workforce-beauty-1/600/400')}
  @{nic='200200000003';first_name='கண்ணன்';last_name='ராஜ்';phone='+94720100003';password_hash='1234';district='15';ds_area='1501';language='ta';verified=$true;rating=4.5;completed_jobs_count=23;abandoned_jobs_count=1;posted_jobs_count=0;applied_jobs_count=7;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C01');skill_ids=@('S101','S107');profile_photo_url='https://randomuser.me/api/portraits/men/33.jpg'}
  @{nic='200200000004';first_name='கவிதா';last_name='துரைராஜா';phone='+94720100004';password_hash='1234';district='16';ds_area='1602';language='ta';verified=$true;rating=4.6;completed_jobs_count=29;abandoned_jobs_count=0;posted_jobs_count=1;applied_jobs_count=5;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C06');skill_ids=@('S601','S602','S603');profile_photo_url='https://randomuser.me/api/portraits/women/34.jpg'}
  @{nic='200200000005';first_name='திரு';last_name='நடராஜா';phone='+94720100005';password_hash='1234';district='17';ds_area='1710';language='ta';verified=$true;rating=4.4;completed_jobs_count=18;abandoned_jobs_count=1;posted_jobs_count=0;applied_jobs_count=4;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C02');skill_ids=@('S201','S203','S204');profile_photo_url='https://randomuser.me/api/portraits/men/35.jpg'}
  @{nic='200200000006';first_name='ஷாலினி';last_name='யோகராஜா';phone='+94720100006';password_hash='1234';district='11';ds_area='1102';language='ta';verified=$true;rating=4.7;completed_jobs_count=27;abandoned_jobs_count=0;posted_jobs_count=1;applied_jobs_count=6;removed_jobs_count=0;availability_status='busy';is_blocked=0;job_category_ids=@('C12');skill_ids=@('S1201','S1203');profile_photo_url='https://randomuser.me/api/portraits/women/36.jpg'}
  @{nic='200200000007';first_name='பிரதீபன்';last_name='செல்வராசா';phone='+94720100007';password_hash='1234';district='12';ds_area='1202';language='ta';verified=$true;rating=4.2;completed_jobs_count=15;abandoned_jobs_count=0;posted_jobs_count=0;applied_jobs_count=3;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C11');skill_ids=@('S1101','S1102');profile_photo_url='https://randomuser.me/api/portraits/men/37.jpg'}
  @{nic='200200000008';first_name='மாலினி';last_name='ரவிச்சந்திரன்';phone='+94720100008';password_hash='1234';district='13';ds_area='1301';language='ta';verified=$true;rating=4.6;completed_jobs_count=21;abandoned_jobs_count=0;posted_jobs_count=0;applied_jobs_count=5;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C14');skill_ids=@('S1401','S1402');profile_photo_url='https://randomuser.me/api/portraits/women/38.jpg'}
  @{nic='200200000009';first_name='ரோஷன்';last_name='சுதாகரன்';phone='+94720100009';password_hash='1234';district='14';ds_area='1401';language='ta';verified=$true;rating=4.3;completed_jobs_count=17;abandoned_jobs_count=0;posted_jobs_count=0;applied_jobs_count=4;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C03');skill_ids=@('S301','S303');profile_photo_url='https://randomuser.me/api/portraits/men/39.jpg'}
  @{nic='200200000010';first_name='பாத்திமா';last_name='ரிஸ்னா';phone='+94720100010';password_hash='1234';district='16';ds_area='1608';language='ta';verified=$true;rating=4.8;completed_jobs_count=33;abandoned_jobs_count=0;posted_jobs_count=1;applied_jobs_count=8;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C04');skill_ids=@('S401','S402','S403');profile_photo_url='https://randomuser.me/api/portraits/women/40.jpg'}
  @{nic='200200000011';first_name='சுரேஷ்';last_name='மோகன்';phone='+94720100011';password_hash='1234';district='19';ds_area='1913';language='ta';verified=$true;rating=4.5;completed_jobs_count=24;abandoned_jobs_count=1;posted_jobs_count=0;applied_jobs_count=6;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C05');skill_ids=@('S501','S502','S505');profile_photo_url='https://randomuser.me/api/portraits/men/41.jpg'}
  @{nic='200200000012';first_name='லட்சுமி';last_name='தேவி';phone='+94720100012';password_hash='1234';district='25';ds_area='2501';language='ta';verified=$true;rating=4.4;completed_jobs_count=18;abandoned_jobs_count=0;posted_jobs_count=0;applied_jobs_count=5;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C08');skill_ids=@('S801','S802','S804');profile_photo_url='https://randomuser.me/api/portraits/women/42.jpg'}
)

$jobs = @(
  @{id='11111111-1111-4111-8111-111111111101';title='නිවසේ බිත්ති අලුත්වැඩියා';description='කොළඹ ප්‍රදේශයේ මායිම් බිත්තිය සහ කුස්සිය අලුත්වැඩියා කිරීමට මේසන් කම්කරුවෙකු අවශ්‍යයි.';employer_nic='200100000001';category='ඉදිකිරීම් සහ කාර්මික';location='0101';status='open';required_skills=@('S101','S107');applied_worker_ids=@('200200000003','200100000005');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111102';title='කඩයට විදුලි රැහැන් සැකසීම';description='ගම්පහ නව කඩයට ලයිට්, ප්ලග් සහ ආරක්ෂක බ්‍රේකර් සවි කිරීම.';employer_nic='200100000002';category='තාක්ෂණික සහ අලුත්වැඩියා';location='0205';status='open';required_skills=@('S501','S505');applied_worker_ids=@('200200000011','200100000007');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111103';title='නිවස පිරිසිදු කිරීමේ කණ්ඩායමක්';description='කළුතර නිවසක් සම්පූර්ණයෙන් පිරිසිදු කිරීම, ජනෙල් සහ මුළුතැන්ගෙය ඇතුළුව.';employer_nic='200100000003';category='නිවාස සහ පිරිසිදු කිරීම්';location='0308';status='in_progress';required_skills=@('S401','S402');applied_worker_ids=@();accepted_worker_ids=@('200200000010');payments=@(@{workerId='200200000010';amount=6500;date='2026-06-15T10:00:00+05:30';note='අත්තිකාරම් ගෙවා ඇත'})}
  @{id='11111111-1111-4111-8111-111111111104';title='දෛනික බෙදාහැරීම් රයිඩර්';description='මහනුවර නගරය අවට භාණ්ඩ බෙදාහැරීමට රයිඩර් කෙනෙකු අවශ්‍යයි.';employer_nic='200100000004';category='ප්‍රවාහන සහ බෙදාහැරීම්';location='0408';status='open';required_skills=@('S203','S204');applied_worker_ids=@('200200000005');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111105';title='තේ වත්තේ අස්වනු සහාය';description='මාතලේ තේ වත්තක කාලීන වැඩ සඳහා සේවකයින් අවශ්‍යයි.';employer_nic='200100000005';category='කෘෂිකර්මය සහ වතු';location='0505';status='open';required_skills=@('S301','S303');applied_worker_ids=@('200200000009');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111106';title='විවාහ උත්සව රූපලාවන්‍ය සහාය';description='ගාල්ල විවාහ උත්සව දෙකකට හිසකෙස් සහ මංගල සැරසිලි සහාය.';employer_nic='200100000006';category='රූපලාවන්‍ය සහ විලාසිතා';location='0708';status='open';required_skills=@('S701','S702');applied_worker_ids=@('200200000002');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111107';title='ජලනල කාන්දු අලුත්වැඩියා';description='මාතර නාන කාමරයේ නල කාන්දු පරීක්ෂා කර අලුත්වැඩියා කිරීම.';employer_nic='200100000007';category='තාක්ෂණික සහ අලුත්වැඩියා';location='0810';status='completed';required_skills=@('S502','S503');applied_worker_ids=@();accepted_worker_ids=@('200200000011');payments=@(@{workerId='200200000011';amount=12000;date='2026-06-10T16:30:00+05:30';note='අවසන් ගෙවීම'})}
  @{id='11111111-1111-4111-8111-111111111108';title='අත්කම් සැරසිලි ඇණවුම';description='හම්බන්තොට කුඩා හෝටලයක පිවිසුමට අත්කම් සැරසිලි නිර්මාණය කිරීම.';employer_nic='200100000008';category='කලා සහ අත්කම්';location='0904';status='open';required_skills=@('S801','S803');applied_worker_ids=@('200200000012');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111109';title='සිල්ලර බඩු තොග සහායක';description='කුරුණෑගල කඩයක සතිඅන්ත තොග පරීක්ෂා කිරීම සහ විකුණුම් සහාය.';employer_nic='200100000009';category='සාමාන්‍ය වෙළඳාම';location='1812';status='open';required_skills=@('S1001','S1002');applied_worker_ids=@('200200000001');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111110';title='සමුපකාර දත්ත ඇතුළත් කිරීම';description='අනුරාධපුර සමුපකාරයට සති දෙකක සිංහල දත්ත ඇතුළත් කිරීමේ වැඩ.';employer_nic='200100000010';category='තොරතුරු තාක්ෂණ සහ ලිපිකරු';location='2001';status='open';required_skills=@('S1201','S1202');applied_worker_ids=@('200200000006');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111111';title='උපන්දින උත්සව සැපයුම් සහාය';description='බදුල්ලේ 80 දෙනෙකුගේ උත්සවයකට ආහාර පිළියෙල කිරීම, සේවය සහ පිරිසිදු කිරීම.';employer_nic='200100000011';category='උත්සව සහ සැපයුම්';location='2201';status='open';required_skills=@('S1301','S1302');applied_worker_ids=@('200200000004');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111112';title='රාත්‍රී ආරක්ෂක සේවය';description='රත්නපුර ගබඩා පරිශ්‍රයකට තාවකාලික රාත්‍රී ආරක්ෂක සේවකයෙකු අවශ්‍යයි.';employer_nic='200100000012';category='ආරක්ෂක සහ මෙහෙයුම්';location='2401';status='open';required_skills=@('S901','S902');applied_worker_ids=@();accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111113';title='யாழ்ப்பாண கடை உதவியாளர்';description='யாழ்ப்பாண நகரில் மாலை நேர கடை உதவியாளர் தேவை.';employer_nic='200200000001';category='பொது வர்த்தகம்';location='1004';status='open';required_skills=@('S1001','S1003');applied_worker_ids=@('200100000009');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111114';title='மணமகள் அலங்கார உதவி';description='திருமண நிகழ்வுக்கு மேக்கப், சேலை அணிவித்தல் மற்றும் வாடிக்கையாளர் உதவி.';employer_nic='200200000002';category='அழகு மற்றும் ஃபேஷன்';location='1005';status='in_progress';required_skills=@('S701','S703');applied_worker_ids=@();accepted_worker_ids=@('200100000006');payments=@(@{workerId='200100000006';amount=8000;date='2026-06-12T09:00:00+05:30';note='முதல் நிகழ்வு கட்டணம்'})}
  @{id='11111111-1111-4111-8111-111111111115';title='மட்டக்களப்பு கட்டுமான தொழிலாளர்கள்';description='தரை அமைப்பு மற்றும் சிமெண்டு வேலைக்கு கட்டுமான உதவியாளர் குழு தேவை.';employer_nic='200200000003';category='நிர்மாணம் மற்றும் தொழிநுட்பம்';location='1501';status='open';required_skills=@('S101','S107');applied_worker_ids=@('200100000001');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111116';title='கல்முனை கேட்டரிங் சமையல்காரர்';description='பள்ளி நிகழ்வுக்கு தமிழ் பேசும் சமையல்காரர் மற்றும் உதவியாளர்கள் தேவை.';employer_nic='200200000004';category='உணவு மற்றும் சுற்றுலா';location='1602';status='open';required_skills=@('S601','S602');applied_worker_ids=@('200100000003','200100000011');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111117';title='திருகோணமலை விநியோக பாதை';description='நகரிலிருந்து அருகிலுள்ள கிராமங்களுக்கு பார்சல் விநியோகம். மோட்டார் சைக்கிள் அவசியம்.';employer_nic='200200000005';category='போக்குவரத்து மற்றும் விநியோகம்';location='1710';status='open';required_skills=@('S201','S203');applied_worker_ids=@('200100000004');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111118';title='மருத்துவமனை வரவேற்பு தரவு பதிவு';description='நோயாளர் பதிவுகள் மற்றும் அழைப்புகளுக்கான தமிழ் அலுவலக உதவி.';employer_nic='200200000006';category='தகவல் தொழில்நுட்பம் மற்றும் எழுத்தர்';location='1102';status='open';required_skills=@('S1201','S1203');applied_worker_ids=@('200100000010');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111119';title='மன்னார் மீன்பிடி வலை பழுது';description='மீன்பிடி கூட்டுறவுக்கு வலை பழுது மற்றும் படகு தயாரிப்பு உதவி.';employer_nic='200200000007';category='மீன்பிடி மற்றும் நீர்வாழ்';location='1202';status='open';required_skills=@('S1101','S1102');applied_worker_ids=@();accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111120';title='மூத்தோர் பராமரிப்பு உதவி';description='மருந்து நினைவூட்டல், உணவு மற்றும் பகல் பராமரிப்பு உதவி.';employer_nic='200200000008';category='சுகாதாரம் மற்றும் பராமரிப்பு';location='1301';status='open';required_skills=@('S1401','S1402');applied_worker_ids=@();accepted_worker_ids=@();payments=@()}
)

$applications = @(
  @{job_id='11111111-1111-4111-8111-111111111101';worker_nic='200200000003';status='applied';applied_at='2026-06-14T08:00:00+05:30'}
  @{job_id='11111111-1111-4111-8111-111111111101';worker_nic='200100000005';status='applied';applied_at='2026-06-14T09:00:00+05:30'}
  @{job_id='11111111-1111-4111-8111-111111111102';worker_nic='200200000011';status='applied';applied_at='2026-06-14T10:00:00+05:30'}
  @{job_id='11111111-1111-4111-8111-111111111102';worker_nic='200100000007';status='applied';applied_at='2026-06-14T11:00:00+05:30'}
  @{job_id='11111111-1111-4111-8111-111111111103';worker_nic='200200000010';status='accepted';applied_at='2026-06-13T08:30:00+05:30'}
  @{job_id='11111111-1111-4111-8111-111111111106';worker_nic='200200000002';status='applied';applied_at='2026-06-15T08:00:00+05:30'}
  @{job_id='11111111-1111-4111-8111-111111111107';worker_nic='200200000011';status='accepted';applied_at='2026-06-09T08:00:00+05:30'}
  @{job_id='11111111-1111-4111-8111-111111111114';worker_nic='200100000006';status='accepted';applied_at='2026-06-11T08:00:00+05:30'}
  @{job_id='11111111-1111-4111-8111-111111111116';worker_nic='200100000003';status='applied';applied_at='2026-06-15T09:30:00+05:30'}
  @{job_id='11111111-1111-4111-8111-111111111116';worker_nic='200100000011';status='applied';applied_at='2026-06-15T10:30:00+05:30'}
  @{job_id='11111111-1111-4111-8111-111111111118';worker_nic='200100000010';status='applied';applied_at='2026-06-16T12:00:00+05:30'}
)

$reviews = @(
  @{id='22222222-2222-4222-8222-222222222201';reviewer_nic='200100000007';worker_nic='200200000011';rating=4.8;comment='වැඩ ඉක්මනින් කරලා පිරිසිදුව අවසන් කළා.';created_at='2026-06-10T18:00:00+05:30'}
  @{id='22222222-2222-4222-8222-222222222202';reviewer_nic='200200000002';worker_nic='200100000006';rating=5.0;comment='மணமகள் அலங்காரம் நேரத்திற்கு, அழகாக முடிந்தது.';created_at='2026-06-12T18:00:00+05:30'}
  @{id='22222222-2222-4222-8222-222222222203';reviewer_nic='200100000003';worker_nic='200200000010';rating=4.7;comment='පිරිසිදු කිරීම වගකීමෙන් කළා.';created_at='2026-06-15T18:00:00+05:30'}
  @{id='22222222-2222-4222-8222-222222222204';reviewer_nic='200200000004';worker_nic='200100000011';rating=4.6;comment='உணவு வழங்கும் உதவி நன்றாக இருந்தது.';created_at='2026-06-16T18:00:00+05:30'}
)

$volunteers = @(
  @{volunteer_id='COL-SI-001';full_name='කොළඹ සිංහල ස්වේච්ඡා 01';password='123456';district='01';language='si';active=$true}
  @{volunteer_id='COL-TA-001';full_name='கொழும்பு தமிழ் தன்னார்வலர் 01';password='123456';district='01';language='ta';active=$true}
  @{volunteer_id='GAM-SI-001';full_name='ගම්පහ සිංහල ස්වේච්ඡා 01';password='123456';district='02';language='si';active=$true}
  @{volunteer_id='GAM-TA-001';full_name='கம்பஹா தமிழ் தன்னார்வலர் 01';password='123456';district='02';language='ta';active=$true}
  @{volunteer_id='TRI-SI-001';full_name='ත්‍රිකුණාමලය සිංහල ස්වේච්ඡා 01';password='123456';district='17';language='si';active=$true}
)

$pendingUsers = @(
  @{id='33333333-3333-4333-8333-333333333301';phone='+94733330001';nic='200300000001';pin='1234';first_name='ඉරේෂා';last_name='දිල්රුක්ෂි';district='කොළඹ';ds_area='කොළඹ';language='si';job_category_ids=@('C04');skill_ids=@('S401','S402');status='pending'}
  @{id='33333333-3333-4333-8333-333333333302';phone='+94733330002';nic='200300000002';pin='1234';first_name='නිරෝෂන්';last_name='කුමාර';district='05';ds_area='0505';language='si';job_category_ids=@('C03');skill_ids=@('S301');status='pending'}
  @{id='33333333-3333-4333-8333-333333333303';phone='+94733330003';nic='200300000003';pin='1234';first_name='விஜய்';last_name='குமார்';district='யாழ்ப்பாணம்';ds_area='நல்லூர்';language='ta';job_category_ids=@('C10');skill_ids=@('S1001');status='pending'}
  @{id='33333333-3333-4333-8333-333333333304';phone='+94733330004';nic='200300000004';pin='1234';first_name='ரிஸ்வானா';last_name='ஹலீம்';district='16';ds_area='1608';language='ta';job_category_ids=@('C06');skill_ids=@('S601');status='pending'}
)

$pendingJobs = @(
  @{id='44444444-4444-4444-8444-444444444401';employer_nic='200100000001';employer_name='සුනිල් පෙරේරා';employer_phone='+94710100001';job_title='කුඩා වහල අලුත්වැඩියා';job_description='වැස්සට කලින් වහලේ කාන්දු තැන් අලුත්වැඩියා කිරීමට කෙනෙකු අවශ්‍යයි.';district='කොළඹ';ds_area='කොළඹ';category='ඉදිකිරීම් සහ කාර්මික';required_skills='S102, S107';payment='රු. 15000';language='si';status='pending'}
  @{id='44444444-4444-4444-8444-444444444402';employer_nic='200200000001';employer_name='அருள் குமார்';employer_phone='+94720100001';job_title='கடை கணக்குப் பதிவு';job_description='மாலை நேர விற்பனை மற்றும் கணக்கு பதிவு உதவி தேவை.';district='10';ds_area='1004';category='தகவல் தொழில்நுட்பம் மற்றும் எழுத்தர்';required_skills='S1201';payment='ஒரு நாளுக்கு ரூ. 2500';language='ta';status='pending'}
  @{id='44444444-4444-4444-8444-444444444403';employer_nic='200100000011';employer_name='පවිත්‍රා මධුෂානි';employer_phone='+94710100011';job_title='ගමේ උත්සවයක ආහාර සැපයුම් සහාය';job_description='සේවය කිරීම සහ අවසාන පිරිසිදු කිරීම සඳහා සහායකයින් තුන්දෙනෙකු අවශ්‍යයි.';district='22';ds_area='2201';category='උත්සව සහ සැපයුම්';required_skills='S1301, S1302';payment='එක් අයෙකුට රු. 5000';language='si';status='pending'}
)

$smsMessages = @(
  @{id='sms-demo-001';phone_number='+94733330001';message='ලියාපදිංචි ඉරේෂා 1234';direction='inbound';status='received';created_at='2026-06-17T08:10:00+05:30';sent_at=$null}
  @{id='sms-demo-002';phone_number='+94733330001';message='ලියාපදිංචි ඉල්ලීම ලැබුණි. ස්වේච්ඡා සේවකයෙකු ඔබගේ ප්‍රදේශය තහවුරු කරයි.';direction='outbound';status='sent';created_at='2026-06-17T08:11:00+05:30';sent_at='2026-06-17T08:11:05+05:30'}
  @{id='sms-demo-003';phone_number='+94720100011';message='உதவி';direction='inbound';status='received';created_at='2026-06-17T09:00:00+05:30';sent_at=$null}
  @{id='sms-demo-004';phone_number='+94720100011';message='கட்டளைகள்: பதிவு, சுயவிவரம், வேலைகள், விண்ணப்பி, உதவி';direction='outbound';status='sent';created_at='2026-06-17T09:00:05+05:30';sent_at='2026-06-17T09:00:10+05:30'}
)

$chats = @(
  @{id='direct_200100000001_200200000003';job_id='11111111-1111-4111-8111-111111111101';participant_ids=@('200100000001','200200000003');type='direct';title='නිවසේ බිත්ති අලුත්වැඩියා';last_message='நாளை காலை வர முடியும்.';last_message_time='2026-06-17T10:20:00+05:30'}
  @{id='group_11111111-1111-4111-8111-111111111103';job_id='11111111-1111-4111-8111-111111111103';participant_ids=@('200100000003','200200000010');type='group';title='නිවස පිරිසිදු කිරීමේ කණ්ඩායමක්';last_message='අත්තිකාරම ලැබුණා, වැඩ පටන් ගත්තා.';last_message_time='2026-06-15T10:30:00+05:30'}
)

$chatMessages = @(
  @{id='55555555-5555-4555-8555-555555555501';chat_id='direct_200100000001_200200000003';sender_id='200100000001';text='අද බිත්තිය බලන්න පුළුවන්ද?';created_at='2026-06-17T10:00:00+05:30'}
  @{id='55555555-5555-4555-8555-555555555502';chat_id='direct_200100000001_200200000003';sender_id='200200000003';text='நாளை காலை வர முடியும்.';created_at='2026-06-17T10:20:00+05:30'}
  @{id='55555555-5555-4555-8555-555555555503';chat_id='group_11111111-1111-4111-8111-111111111103';sender_id='200100000003';text='අත්තිකාරම යැව්වා. මුලින් කුස්සියෙන් පටන් ගන්න.';created_at='2026-06-15T10:10:00+05:30'}
  @{id='55555555-5555-4555-8555-555555555504';chat_id='group_11111111-1111-4111-8111-111111111103';sender_id='200200000010';text='අත්තිකාරම ලැබුණා, වැඩ පටන් ගත්තා.';created_at='2026-06-15T10:30:00+05:30'}
)

$legacyFixes = @(
  @{table='jobs';filter='id=eq.0271e1b4-841d-43fc-a3e3-5dd705e547e6';values=@{title='ගම්පහ නිවස ඉදිකිරීම් කාර්යය';description='නිවසක ඉදිකිරීම් සඳහා මේසන් කම්කරුවන් විසිදෙනෙකු අවශ්‍යයි.';employer_nic='200100000001';category='ඉදිකිරීම් සහ කාර්මික';location='0205';status='open';required_skills=@('S101','S107');applied_worker_ids=@('200100000005');accepted_worker_ids=@();payments=@()}}
  @{table='jobs';filter='id=eq.c1f1207e-faa1-40b1-9433-a7e970f804a0';values=@{title='ගාල්ල වත්තේ කෘෂිකාර්මික සහාය';description='ගාල්ල ප්‍රදේශයේ වත්තක වගා කටයුතු සඳහා දෛනික සේවකයෙකු අවශ්‍යයි.';employer_nic='100022222222';category='කෘෂිකර්මය සහ වතු';location='0901';status='open';required_skills=@('S301');applied_worker_ids=@();accepted_worker_ids=@();payments=@()}}
  @{table='users';filter='nic=eq.TEMP_';values=@{first_name='තාවකාලික';last_name='භාවිතා කරන්නා';language='si';district='01';ds_area='0101';verified=$false}}
  @{table='users';filter="nic=eq.$([uri]::EscapeDataString('TEMP_ைபேசி எண்'))";values=@{first_name='தற்காலிக';last_name='பயனர்';language='ta';district='10';ds_area='1004';verified=$false}}
)

foreach ($u in $users) {
  $u.Remove('portfolio_photo_urls') | Out-Null
}

$results = [ordered]@{}
$results.users = Upsert-Rows -Table 'users' -Rows $users -Conflict 'nic'
$results.jobs = Upsert-Rows -Table 'jobs' -Rows $jobs -Conflict 'id'
$results.applications = Upsert-Rows -Table 'applications' -Rows $applications -Conflict 'job_id,worker_nic'
$results.reviews = Upsert-Rows -Table 'reviews' -Rows $reviews -Conflict 'id'
$results.sms_messages = Upsert-Rows -Table 'sms_messages' -Rows $smsMessages -Conflict 'id'
$results.chats = Upsert-Rows -Table 'chats' -Rows $chats -Conflict 'id'
$results.chat_messages = Upsert-Rows -Table 'chat_messages' -Rows $chatMessages -Conflict 'id'
$results.volunteers = Upsert-Rows -Table 'volunteers' -Rows $volunteers -Conflict 'volunteer_id'
$results.pending_user_registrations = Upsert-Rows -Table 'pending_user_registrations' -Rows $pendingUsers -Conflict 'id'
$results.pending_job_posts = Upsert-Rows -Table 'pending_job_posts' -Rows $pendingJobs -Conflict 'id'
$results.legacy_cleanup = $true
foreach ($fix in $legacyFixes) {
  if (-not (Update-Rows -Table $fix['table'] -Filter $fix['filter'] -Values $fix['values'])) {
    $results.legacy_cleanup = $false
  }
}

Write-Output 'VIVA_SEED_SUMMARY'
Write-Output "users=$($users.Count)"
Write-Output "jobs=$($jobs.Count)"
Write-Output "applications=$($applications.Count)"
Write-Output "reviews=$($reviews.Count)"
Write-Output "volunteers=$($volunteers.Count)"
Write-Output "pending_users=$($pendingUsers.Count)"
Write-Output "pending_jobs=$($pendingJobs.Count)"
Write-Output 'admin_pin=9421'
Write-Output 'demo_sinhala_user=200100000001 / 1234'
Write-Output 'demo_tamil_user=200200000001 / 1234'
Write-Output 'demo_volunteer_sinhala=COL-SI-001 / 123456'
Write-Output 'demo_volunteer_tamil=COL-TA-001 / 123456'

$failed = @($results.GetEnumerator() | Where-Object { -not $_.Value } | ForEach-Object { $_.Key })
if ($failed.Count -gt 0) {
  Write-Output "seed_partial=true"
  Write-Output "failed_tables=$($failed -join ',')"
  Write-Output 'Set SUPABASE_SERVICE_ROLE_KEY or run the SQL migration if protected tables fail.'
  $criticalFailures = @($failed | Where-Object { $_ -in @('users', 'jobs', 'applications') })
  if ($criticalFailures.Count -gt 0) {
    exit 2
  }
  exit 0
}

Write-Output 'seed_partial=false'
