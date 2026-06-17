$ErrorActionPreference = 'Stop'

$base = 'https://informal-worker.onrender.com'

$workers = @(
  @{nic='200011111111';pin='1234';first_name='සුනිල්';last_name='පෙරේරා';phone='0711111111';district='01';ds_area='0101';language='si';job_category_ids=@('C01','C05');skill_ids=@('S101','S501','S502')},
  @{nic='200022222222';pin='1234';first_name='නදීෂා';last_name='ප්‍රනාන්දු';phone='0722222222';district='02';ds_area='0205';language='si';job_category_ids=@('C05');skill_ids=@('S501','S502','S505')},
  @{nic='200033333333';pin='1234';first_name='කුමාරි';last_name='ජයසූරිය';phone='0733333333';district='03';ds_area='0308';language='si';job_category_ids=@('C04','C06');skill_ids=@('S401','S402','S403','S601')},
  @{nic='200044444444';pin='1234';first_name='රුවන්';last_name='බණ්ඩාර';phone='0744444444';district='04';ds_area='0401';language='si';job_category_ids=@('C02');skill_ids=@('S201','S202','S203')},
  @{nic='200055555555';pin='1234';first_name='සමන්';last_name='හේරත්';phone='0755555555';district='05';ds_area='0505';language='si';job_category_ids=@('C03');skill_ids=@('S301','S302','S303')},
  @{nic='200066666666';pin='1234';first_name='අනූෂා';last_name='විජේසිංහ';phone='0766666666';district='06';ds_area='0604';language='si';job_category_ids=@('C06','C13');skill_ids=@('S601','S602','S603','S1301')},
  @{nic='200077777777';pin='1234';first_name='மீனா';last_name='சிவபாலன்';phone='0777777777';district='10';ds_area='1005';language='ta';job_category_ids=@('C07');skill_ids=@('S701','S702','S703')},
  @{nic='200088888888';pin='1234';first_name='கண்ணன்';last_name='ராஜ்';phone='0788888888';district='15';ds_area='1501';language='ta';job_category_ids=@('C05');skill_ids=@('S502','S503','S505')},
  @{nic='200099999999';pin='1234';first_name='கவிதா';last_name='துரைராஜா';phone='0799999999';district='16';ds_area='1602';language='ta';job_category_ids=@('C08');skill_ids=@('S801','S802','S803','S804')},
  @{nic='200010101010';pin='1234';first_name='அருள்';last_name='குமார்';phone='0701010101';district='10';ds_area='1004';language='ta';job_category_ids=@('C10','C12');skill_ids=@('S1001','S1002','S1003','S1201')}
)

$jobs = @(
  @{title='නිවසේ බිත්ති අලුත්වැඩියා';description='කොළඹ ප්‍රදේශයේ මායිම් බිත්තිය සහ කුස්සිය අලුත්වැඩියා කිරීමට මේසන් කම්කරුවෙකු අවශ්‍යයි.';area='0101';skill_ids_needed=@('S101','S102');status='open'},
  @{title='කඩයට විදුලි රැහැන් සැකසීම';description='ගම්පහ නව කඩයට ලයිට්, ප්ලග් සහ ආරක්ෂක බ්‍රේකර් සවි කිරීම.';area='0205';skill_ids_needed=@('S501');status='open'},
  @{title='නිවස පිරිසිදු කිරීමේ කණ්ඩායමක්';description='කළුතර නිවසක් සම්පූර්ණයෙන් පිරිසිදු කිරීම, ජනෙල් සහ මුළුතැන්ගෙය ඇතුළුව.';area='0308';skill_ids_needed=@('S401','S402','S403');status='open'},
  @{title='දෛනික බෙදාහැරීම් රයිඩර්';description='මහනුවර නගරය අවට භාණ්ඩ බෙදාහැරීමට රයිඩර් කෙනෙකු අවශ්‍යයි.';area='0401';skill_ids_needed=@('S202','S203');status='open'},
  @{title='තේ වත්තේ අස්වනු සහාය';description='මාතලේ තේ වත්තක කාලීන වැඩ සඳහා සේවකයින් අවශ්‍යයි.';area='0505';skill_ids_needed=@('S303');status='open'},
  @{title='උත්සව ආහාර සැපයුම් සහාය';description='නුවරඑළිය උත්සවයකට ආහාර පිළියෙල කිරීම, සේවය සහ පිරිසිදු කිරීම.';area='0604';skill_ids_needed=@('S601','S1301');status='open'},
  @{title='மணமகள் அலங்கார உதவி';description='திருமண நிகழ்வுக்கு மேக்கப், சேலை அணிவித்தல் மற்றும் வாடிக்கையாளர் உதவி.';area='1005';skill_ids_needed=@('S701','S702');status='open'},
  @{title='மட்டக்களப்பு கட்டுமான தொழிலாளர்கள்';description='தரை அமைப்பு மற்றும் சிமெண்டு வேலைக்கு கட்டுமான உதவியாளர் குழு தேவை.';area='1501';skill_ids_needed=@('S502');status='open'},
  @{title='கல்முனை கேட்டரிங் சமையல்காரர்';description='பள்ளி நிகழ்வுக்கு தமிழ் பேசும் சமையல்காரர் மற்றும் உதவியாளர்கள் தேவை.';area='1602';skill_ids_needed=@('S803');status='open'},
  @{title='யாழ்ப்பாண கடை உதவியாளர்';description='யாழ்ப்பாண நகரில் மாலை நேர கடை உதவியாளர் தேவை.';area='1004';skill_ids_needed=@('S1001');status='open'},
  @{title='කාර්යාලය පින්තාරු කිරීම';description='කාර්යාලය පින්තාරු කර සැරසිලි අවසන් කළා.';area='0101';skill_ids_needed=@('S104');status='completed'},
  @{title='குளியலறை புதுப்பிப்பு';description='குளியலறை டைல்கள் மற்றும் பொருத்துதல்கள் முடிந்தது.';area='0205';skill_ids_needed=@('S501');status='completed'}
)

$registered = 0
$registerErrors = 0
$registeredExisting = 0

foreach ($w in $workers) {
  try {
    Invoke-RestMethod -Method Post -Uri "$base/auth/register" -ContentType 'application/json; charset=utf-8' -Body ($w | ConvertTo-Json -Depth 8) | Out-Null
    $registered++
  } catch {
    $registerErrors++
    if ($_.Exception.Message -match 'already|exists|409|400') {
      $registeredExisting++
    }
  }
}

$loginBody = @{ nic = '200011111111'; pin = '1234' } | ConvertTo-Json
$token = $null
$loginOk = $false

try {
  $loginResp = Invoke-RestMethod -Method Post -Uri "$base/auth/login" -ContentType 'application/json; charset=utf-8' -Body $loginBody
  if ($loginResp.access_token) {
    $token = $loginResp.access_token
    $loginOk = $true
  } elseif ($loginResp.token) {
    $token = $loginResp.token
    $loginOk = $true
  }
} catch {
  $loginOk = $false
}

$jobsCreated = 0
$jobErrors = 0

if ($loginOk -and $token) {
  $headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json; charset=utf-8' }
  foreach ($j in $jobs) {
    try {
      Invoke-RestMethod -Method Post -Uri "$base/jobs" -Headers $headers -Body ($j | ConvertTo-Json -Depth 8) | Out-Null
      $jobsCreated++
    } catch {
      $jobErrors++
    }
  }
}

Write-Output "SEED_SUMMARY"
Write-Output "workers_registered=$registered"
Write-Output "workers_errors=$registerErrors"
Write-Output "workers_existing_or_duplicates=$registeredExisting"
Write-Output "login_ok=$loginOk"
Write-Output "jobs_created=$jobsCreated"
Write-Output "jobs_errors=$jobErrors"
Write-Output "demo_nic=200011111111"
Write-Output "demo_pin=1234"
