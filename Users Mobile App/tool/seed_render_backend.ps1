$ErrorActionPreference = 'Stop'

$base = 'https://informal-worker.onrender.com'

$workers = @(
  @{nic='200011111111';pin='1234';first_name='Colombo';last_name='Worker';phone='0711111111';district='Colombo';ds_area='Colombo';language='en';job_category_ids=@('C01','C05');skill_ids=@('S101','S501','S502')},
  @{nic='200022222222';pin='1234';first_name='Kasun';last_name='Electrician';phone='0722222222';district='Gampaha';ds_area='Gampaha';language='en';job_category_ids=@('C05');skill_ids=@('S501','S502','S505')},
  @{nic='200033333333';pin='1234';first_name='Kumari';last_name='Housekeeper';phone='0733333333';district='Kalutara';ds_area='Kalutara';language='en';job_category_ids=@('C04','C06');skill_ids=@('S401','S402','S403','S601')},
  @{nic='200044444444';pin='1234';first_name='Ravi';last_name='Driver';phone='0744444444';district='Kandy';ds_area='Akurana';language='en';job_category_ids=@('C02');skill_ids=@('S201','S202','S203')},
  @{nic='200055555555';pin='1234';first_name='Samantha';last_name='Farmer';phone='0755555555';district='Matale';ds_area='Matale';language='en';job_category_ids=@('C03');skill_ids=@('S301','S302','S303')},
  @{nic='200066666666';pin='1234';first_name='Anura';last_name='Chef';phone='0766666666';district='Nuwara Eliya';ds_area='Nuwara Eliya';language='en';job_category_ids=@('C06','C13');skill_ids=@('S601','S602','S603','S1301')},
  @{nic='200077777777';pin='1234';first_name='Priya';last_name='Beautician';phone='0777777777';district='Galle';ds_area='Galle';language='en';job_category_ids=@('C07');skill_ids=@('S701','S702','S703')},
  @{nic='200088888888';pin='1234';first_name='Dinesh';last_name='Plumber';phone='0788888888';district='Matara';ds_area='Matara';language='en';job_category_ids=@('C05');skill_ids=@('S502','S503','S505')},
  @{nic='200099999999';pin='1234';first_name='Thulani';last_name='Artist';phone='0799999999';district='Hambantota';ds_area='Hambantota';language='en';job_category_ids=@('C08');skill_ids=@('S801','S802','S803','S804')},
  @{nic='200010101010';pin='1234';first_name='Amara';last_name='Shopkeeper';phone='0701010101';district='Jaffna';ds_area='Jaffna';language='en';job_category_ids=@('C10','C12');skill_ids=@('S1001','S1002','S1003','S1201')}
)

$jobs = @(
  @{title='Home Renovation & Repair';description='Looking for skilled masons and carpenters for a 3-month home renovation project in Colombo.';area='Colombo';skill_ids_needed=@('S101','S102');status='open'},
  @{title='Electrical Installation';description='Need qualified electrician for commercial building electrical setup.';area='Gampaha';skill_ids_needed=@('S501');status='open'},
  @{title='Full House Cleaning Service';description='Comprehensive house cleaning required for 2500 sq.ft property.';area='Kalutara';skill_ids_needed=@('S401','S402','S403');status='open'},
  @{title='Delivery & Transportation';description='Need reliable drivers for daily goods delivery.';area='Kandy';skill_ids_needed=@('S202','S203');status='open'},
  @{title='Agricultural Work - Tea Plantation';description='Seasonal tea plucking role on established plantation.';area='Matale';skill_ids_needed=@('S303');status='open'},
  @{title='Event Catering & Food Preparation';description='Professional chef needed for corporate event catering next month.';area='Nuwara Eliya';skill_ids_needed=@('S601','S1301');status='open'},
  @{title='Salon Services - Hair & Beauty';description='Looking for experienced beautician for wedding party services.';area='Galle';skill_ids_needed=@('S701','S702');status='open'},
  @{title='Plumbing & Water System Installation';description='New residential complex needs complete plumbing installation.';area='Matara';skill_ids_needed=@('S502');status='open'},
  @{title='Interior Design & Decoration';description='Need creative professional for office interior decoration concept.';area='Hambantota';skill_ids_needed=@('S803');status='open'},
  @{title='Retail Shop Management';description='Experienced shop manager for new retail outlet in Jaffna.';area='Jaffna';skill_ids_needed=@('S1001');status='open'},
  @{title='Office Painting';description='Office space painted and decorated - COMPLETED';area='Colombo';skill_ids_needed=@('S104');status='completed'},
  @{title='Bathroom Renovation';description='Bathroom tiles and fixtures installed - COMPLETED';area='Gampaha';skill_ids_needed=@('S501');status='completed'}
)

$registered = 0
$registerErrors = 0
$registeredExisting = 0

foreach ($w in $workers) {
  try {
    Invoke-RestMethod -Method Post -Uri "$base/auth/register" -ContentType 'application/json' -Body ($w | ConvertTo-Json -Depth 8) | Out-Null
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
  $loginResp = Invoke-RestMethod -Method Post -Uri "$base/auth/login" -ContentType 'application/json' -Body $loginBody
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
  $headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }
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
