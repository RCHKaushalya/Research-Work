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
  'Content-Type' = 'application/json'
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

$users = @(
  @{nic='200100000001';first_name='Sunil';last_name='Perera';phone='+94710100001';password_hash='1234';district='01';ds_area='0101';language='si';verified=$true;rating=4.8;completed_jobs_count=34;abandoned_jobs_count=1;posted_jobs_count=2;applied_jobs_count=5;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C01');skill_ids=@('S101','S102','S107');profile_photo_url='https://randomuser.me/api/portraits/men/11.jpg';portfolio_photo_urls=@('https://picsum.photos/seed/workforce-masonry-1/600/400','https://picsum.photos/seed/workforce-masonry-2/600/400')}
  @{nic='200100000002';first_name='Nadeesha';last_name='Fernando';phone='+94710100002';password_hash='1234';district='02';ds_area='0205';language='si';verified=$true;rating=4.7;completed_jobs_count=28;abandoned_jobs_count=0;posted_jobs_count=1;applied_jobs_count=7;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C05');skill_ids=@('S501','S502','S505');profile_photo_url='https://randomuser.me/api/portraits/women/12.jpg';portfolio_photo_urls=@('https://picsum.photos/seed/workforce-electric-1/600/400')}
  @{nic='200100000003';first_name='Kumari';last_name='Jayasuriya';phone='+94710100003';password_hash='1234';district='03';ds_area='0308';language='si';verified=$true;rating=4.9;completed_jobs_count=47;abandoned_jobs_count=0;posted_jobs_count=0;applied_jobs_count=9;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C04','C06');skill_ids=@('S401','S402','S403','S601');profile_photo_url='https://randomuser.me/api/portraits/women/13.jpg';portfolio_photo_urls=@('https://picsum.photos/seed/workforce-cleaning-1/600/400')}
  @{nic='200100000004';first_name='Ruwan';last_name='Bandara';phone='+94710100004';password_hash='1234';district='04';ds_area='0408';language='si';verified=$true;rating=4.6;completed_jobs_count=39;abandoned_jobs_count=2;posted_jobs_count=1;applied_jobs_count=6;removed_jobs_count=0;availability_status='busy';is_blocked=0;job_category_ids=@('C02');skill_ids=@('S202','S203','S204');profile_photo_url='https://randomuser.me/api/portraits/men/14.jpg'}
  @{nic='200100000005';first_name='Saman';last_name='Herath';phone='+94710100005';password_hash='1234';district='05';ds_area='0505';language='si';verified=$true;rating=4.4;completed_jobs_count=22;abandoned_jobs_count=1;posted_jobs_count=0;applied_jobs_count=4;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C03');skill_ids=@('S301','S302','S303');profile_photo_url='https://randomuser.me/api/portraits/men/15.jpg'}
  @{nic='200100000006';first_name='Anusha';last_name='Wijesinghe';phone='+94710100006';password_hash='1234';district='07';ds_area='0708';language='si';verified=$true;rating=4.9;completed_jobs_count=58;abandoned_jobs_count=0;posted_jobs_count=1;applied_jobs_count=8;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C07');skill_ids=@('S701','S702','S703');profile_photo_url='https://randomuser.me/api/portraits/women/16.jpg'}
  @{nic='200100000007';first_name='Chathura';last_name='Silva';phone='+94710100007';password_hash='1234';district='08';ds_area='0810';language='si';verified=$true;rating=4.5;completed_jobs_count=26;abandoned_jobs_count=0;posted_jobs_count=2;applied_jobs_count=3;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C05');skill_ids=@('S502','S503','S505');profile_photo_url='https://randomuser.me/api/portraits/men/17.jpg'}
  @{nic='200100000008';first_name='Mahesh';last_name='Priyantha';phone='+94710100008';password_hash='1234';district='09';ds_area='0904';language='si';verified=$true;rating=4.3;completed_jobs_count=19;abandoned_jobs_count=1;posted_jobs_count=0;applied_jobs_count=5;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C08');skill_ids=@('S801','S802','S803');profile_photo_url='https://randomuser.me/api/portraits/men/18.jpg'}
  @{nic='200100000009';first_name='Dilan';last_name='Lakmal';phone='+94710100009';password_hash='1234';district='18';ds_area='1812';language='si';verified=$true;rating=4.2;completed_jobs_count=16;abandoned_jobs_count=0;posted_jobs_count=0;applied_jobs_count=6;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C10');skill_ids=@('S1001','S1002','S1003');profile_photo_url='https://randomuser.me/api/portraits/men/19.jpg'}
  @{nic='200100000010';first_name='Himali';last_name='Ranasinghe';phone='+94710100010';password_hash='1234';district='20';ds_area='2001';language='si';verified=$true;rating=4.6;completed_jobs_count=25;abandoned_jobs_count=0;posted_jobs_count=1;applied_jobs_count=4;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C12');skill_ids=@('S1201','S1202');profile_photo_url='https://randomuser.me/api/portraits/women/20.jpg'}
  @{nic='200100000011';first_name='Pavithra';last_name='Madushani';phone='+94710100011';password_hash='1234';district='22';ds_area='2201';language='si';verified=$true;rating=4.7;completed_jobs_count=31;abandoned_jobs_count=0;posted_jobs_count=0;applied_jobs_count=6;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C13');skill_ids=@('S1301','S1302');profile_photo_url='https://randomuser.me/api/portraits/women/21.jpg'}
  @{nic='200100000012';first_name='Gayan';last_name='Sampath';phone='+94710100012';password_hash='1234';district='24';ds_area='2401';language='si';verified=$true;rating=4.1;completed_jobs_count=14;abandoned_jobs_count=1;posted_jobs_count=0;applied_jobs_count=5;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C09');skill_ids=@('S901','S902');profile_photo_url='https://randomuser.me/api/portraits/men/22.jpg'}
  @{nic='200200000001';first_name='Arul';last_name='Kumar';phone='+94720100001';password_hash='1234';district='10';ds_area='1004';language='ta';verified=$true;rating=4.8;completed_jobs_count=36;abandoned_jobs_count=0;posted_jobs_count=1;applied_jobs_count=8;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C10');skill_ids=@('S1001','S1002');profile_photo_url='https://randomuser.me/api/portraits/men/31.jpg'}
  @{nic='200200000002';first_name='Meena';last_name='Sivapalan';phone='+94720100002';password_hash='1234';district='10';ds_area='1005';language='ta';verified=$true;rating=4.9;completed_jobs_count=44;abandoned_jobs_count=0;posted_jobs_count=0;applied_jobs_count=9;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C07');skill_ids=@('S701','S702','S703');profile_photo_url='https://randomuser.me/api/portraits/women/32.jpg';portfolio_photo_urls=@('https://picsum.photos/seed/workforce-beauty-1/600/400')}
  @{nic='200200000003';first_name='Kannan';last_name='Raj';phone='+94720100003';password_hash='1234';district='15';ds_area='1501';language='ta';verified=$true;rating=4.5;completed_jobs_count=23;abandoned_jobs_count=1;posted_jobs_count=0;applied_jobs_count=7;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C01');skill_ids=@('S101','S107');profile_photo_url='https://randomuser.me/api/portraits/men/33.jpg'}
  @{nic='200200000004';first_name='Kavitha';last_name='Thurairajah';phone='+94720100004';password_hash='1234';district='16';ds_area='1602';language='ta';verified=$true;rating=4.6;completed_jobs_count=29;abandoned_jobs_count=0;posted_jobs_count=1;applied_jobs_count=5;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C06');skill_ids=@('S601','S602','S603');profile_photo_url='https://randomuser.me/api/portraits/women/34.jpg'}
  @{nic='200200000005';first_name='Thiru';last_name='Nadarajah';phone='+94720100005';password_hash='1234';district='17';ds_area='1710';language='ta';verified=$true;rating=4.4;completed_jobs_count=18;abandoned_jobs_count=1;posted_jobs_count=0;applied_jobs_count=4;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C02');skill_ids=@('S201','S203','S204');profile_photo_url='https://randomuser.me/api/portraits/men/35.jpg'}
  @{nic='200200000006';first_name='Shalini';last_name='Yogarajah';phone='+94720100006';password_hash='1234';district='11';ds_area='1102';language='ta';verified=$true;rating=4.7;completed_jobs_count=27;abandoned_jobs_count=0;posted_jobs_count=1;applied_jobs_count=6;removed_jobs_count=0;availability_status='busy';is_blocked=0;job_category_ids=@('C12');skill_ids=@('S1201','S1203');profile_photo_url='https://randomuser.me/api/portraits/women/36.jpg'}
  @{nic='200200000007';first_name='Pradeepan';last_name='Selvarasa';phone='+94720100007';password_hash='1234';district='12';ds_area='1202';language='ta';verified=$true;rating=4.2;completed_jobs_count=15;abandoned_jobs_count=0;posted_jobs_count=0;applied_jobs_count=3;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C11');skill_ids=@('S1101','S1102');profile_photo_url='https://randomuser.me/api/portraits/men/37.jpg'}
  @{nic='200200000008';first_name='Malini';last_name='Ravichandran';phone='+94720100008';password_hash='1234';district='13';ds_area='1301';language='ta';verified=$true;rating=4.6;completed_jobs_count=21;abandoned_jobs_count=0;posted_jobs_count=0;applied_jobs_count=5;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C14');skill_ids=@('S1401','S1402');profile_photo_url='https://randomuser.me/api/portraits/women/38.jpg'}
  @{nic='200200000009';first_name='Roshan';last_name='Suthakaran';phone='+94720100009';password_hash='1234';district='14';ds_area='1401';language='ta';verified=$true;rating=4.3;completed_jobs_count=17;abandoned_jobs_count=0;posted_jobs_count=0;applied_jobs_count=4;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C03');skill_ids=@('S301','S303');profile_photo_url='https://randomuser.me/api/portraits/men/39.jpg'}
  @{nic='200200000010';first_name='Fathima';last_name='Rizna';phone='+94720100010';password_hash='1234';district='16';ds_area='1608';language='ta';verified=$true;rating=4.8;completed_jobs_count=33;abandoned_jobs_count=0;posted_jobs_count=1;applied_jobs_count=8;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C04');skill_ids=@('S401','S402','S403');profile_photo_url='https://randomuser.me/api/portraits/women/40.jpg'}
  @{nic='200200000011';first_name='Suresh';last_name='Mohan';phone='+94720100011';password_hash='1234';district='19';ds_area='1913';language='ta';verified=$true;rating=4.5;completed_jobs_count=24;abandoned_jobs_count=1;posted_jobs_count=0;applied_jobs_count=6;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C05');skill_ids=@('S501','S502','S505');profile_photo_url='https://randomuser.me/api/portraits/men/41.jpg'}
  @{nic='200200000012';first_name='Lakshmi';last_name='Devi';phone='+94720100012';password_hash='1234';district='25';ds_area='2501';language='ta';verified=$true;rating=4.4;completed_jobs_count=18;abandoned_jobs_count=0;posted_jobs_count=0;applied_jobs_count=5;removed_jobs_count=0;availability_status='available';is_blocked=0;job_category_ids=@('C08');skill_ids=@('S801','S802','S804');profile_photo_url='https://randomuser.me/api/portraits/women/42.jpg'}
)

$jobs = @(
  @{id='11111111-1111-4111-8111-111111111101';title='House Masonry Repair';description='Boundary wall and kitchen repair. Sinhala-speaking employer, two-day work, tools provided.';employer_nic='200100000001';category='Construction & Technical';location='0101';status='open';required_skills=@('S101','S107');applied_worker_ids=@('200200000003','200100000005');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111102';title='Electrical Wiring for Shop';description='New retail shop wiring, lights, and safety breaker setup in Gampaha.';employer_nic='200100000002';category='Technical Repair';location='0205';status='open';required_skills=@('S501','S505');applied_worker_ids=@('200200000011','200100000007');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111103';title='Deep Cleaning Team Needed';description='Full house cleaning, windows, kitchen, and garden edge cleaning.';employer_nic='200100000003';category='Home & Cleaning';location='0308';status='in_progress';required_skills=@('S401','S402');applied_worker_ids=@();accepted_worker_ids=@('200200000010');payments=@(@{workerId='200200000010';amount=6500;date='2026-06-15T10:00:00+05:30';note='Advance paid'})}
  @{id='11111111-1111-4111-8111-111111111104';title='Daily Delivery Rider';description='Groceries delivery route around Kandy city. Morning and evening shifts.';employer_nic='200100000004';category='Transport & Delivery';location='0408';status='open';required_skills=@('S203','S204');applied_worker_ids=@('200200000005');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111105';title='Tea Estate Harvest Support';description='Seasonal plantation support with accommodation and meals.';employer_nic='200100000005';category='Agriculture & Plantation';location='0505';status='open';required_skills=@('S301','S303');applied_worker_ids=@('200200000009');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111106';title='Wedding Salon Support';description='Hair dressing and bridal party support for two wedding events.';employer_nic='200100000006';category='Beauty & Fashion';location='0708';status='open';required_skills=@('S701','S702');applied_worker_ids=@('200200000002');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111107';title='Plumbing Leak Repair';description='Bathroom leak inspection and pipe replacement in Matara.';employer_nic='200100000007';category='Technical Repair';location='0810';status='completed';required_skills=@('S502','S503');applied_worker_ids=@();accepted_worker_ids=@('200200000011');payments=@(@{workerId='200200000011';amount=12000;date='2026-06-10T16:30:00+05:30';note='Final settlement'})}
  @{id='11111111-1111-4111-8111-111111111108';title='Handmade Decor Order';description='Craft decorations for small hotel lobby. Materials reimbursed separately.';employer_nic='200100000008';category='Arts & Crafts';location='0904';status='open';required_skills=@('S801','S803');applied_worker_ids=@('200200000012');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111109';title='Retail Inventory Assistant';description='Weekend stock checking and point-of-sale support.';employer_nic='200100000009';category='General Trade';location='1812';status='open';required_skills=@('S1001','S1002');applied_worker_ids=@('200200000001');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111110';title='Data Entry for Cooperative';description='Two-week Sinhala data entry project with basic computer skills.';employer_nic='200100000010';category='IT & Clerical';location='2001';status='open';required_skills=@('S1201','S1202');applied_worker_ids=@('200200000006');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111111';title='Birthday Catering Helper';description='Catering prep, serving, and cleanup for 80 guests.';employer_nic='200100000011';category='Events & Catering';location='2201';status='open';required_skills=@('S1301','S1302');applied_worker_ids=@('200200000004');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111112';title='Security Night Shift';description='Temporary night watch for warehouse premises.';employer_nic='200100000012';category='Security & Operations';location='2401';status='open';required_skills=@('S901','S902');applied_worker_ids=@();accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111113';title='யாழ்ப்பாண கடை உதவியாளர்';description='Tamil retail assistant needed for evening shift in Jaffna town.';employer_nic='200200000001';category='General Trade';location='1004';status='open';required_skills=@('S1001','S1003');applied_worker_ids=@('200100000009');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111114';title='Bridal Makeup Assistant';description='Wedding makeup support, saree dressing, and customer handling.';employer_nic='200200000002';category='Beauty & Fashion';location='1005';status='in_progress';required_skills=@('S701','S703');applied_worker_ids=@();accepted_worker_ids=@('200100000006');payments=@(@{workerId='200100000006';amount=8000;date='2026-06-12T09:00:00+05:30';note='First event paid'})}
  @{id='11111111-1111-4111-8111-111111111115';title='Batticaloa Site Labour';description='Construction helper team needed for flooring and cement work.';employer_nic='200200000003';category='Construction & Technical';location='1501';status='open';required_skills=@('S101','S107');applied_worker_ids=@('200100000001');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111116';title='Kalmunai Catering Cook';description='Tamil/Sinhala event cook for school function, 120 plates.';employer_nic='200200000004';category='Food & Tourism';location='1602';status='open';required_skills=@('S601','S602');applied_worker_ids=@('200100000003','200100000011');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111117';title='Trincomalee Delivery Route';description='Parcel delivery from city to nearby villages. Motorbike required.';employer_nic='200200000005';category='Transport & Delivery';location='1710';status='open';required_skills=@('S201','S203');applied_worker_ids=@('200100000004');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111118';title='Clinic Reception Data Entry';description='Tamil and English clerical work, patient records and appointment calls.';employer_nic='200200000006';category='IT & Clerical';location='1102';status='open';required_skills=@('S1201','S1203');applied_worker_ids=@('200100000010');accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111119';title='Fishing Net Repair';description='Mannar fishing cooperative needs net repair and boat preparation support.';employer_nic='200200000007';category='Fishing & Aquaculture';location='1202';status='open';required_skills=@('S1101','S1102');applied_worker_ids=@();accepted_worker_ids=@();payments=@()}
  @{id='11111111-1111-4111-8111-111111111120';title='Elder Care Assistant';description='Daytime care support for elderly patient, medicine reminders and meals.';employer_nic='200200000008';category='Health & Care';location='1301';status='open';required_skills=@('S1401','S1402');applied_worker_ids=@();accepted_worker_ids=@();payments=@()}
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
  @{id='22222222-2222-4222-8222-222222222201';reviewer_nic='200100000007';worker_nic='200200000011';rating=4.8;comment='Quick repair and clean finish.';created_at='2026-06-10T18:00:00+05:30'}
  @{id='22222222-2222-4222-8222-222222222202';reviewer_nic='200200000002';worker_nic='200100000006';rating=5.0;comment='Bridal work was neat and punctual.';created_at='2026-06-12T18:00:00+05:30'}
  @{id='22222222-2222-4222-8222-222222222203';reviewer_nic='200100000003';worker_nic='200200000010';rating=4.7;comment='Very responsible cleaning support.';created_at='2026-06-15T18:00:00+05:30'}
  @{id='22222222-2222-4222-8222-222222222204';reviewer_nic='200200000004';worker_nic='200100000011';rating=4.6;comment='Good catering helper, communicated well.';created_at='2026-06-16T18:00:00+05:30'}
)

$volunteers = @(
  @{volunteer_id='COL-SI-001';full_name='Colombo Sinhala Volunteer 01';password='123456';district='01';language='si';active=$true}
  @{volunteer_id='COL-TA-001';full_name='Colombo Tamil Volunteer 01';password='123456';district='01';language='ta';active=$true}
  @{volunteer_id='GAM-SI-001';full_name='Gampaha Sinhala Volunteer 01';password='123456';district='02';language='si';active=$true}
  @{volunteer_id='GAM-TA-001';full_name='Gampaha Tamil Volunteer 01';password='123456';district='02';language='ta';active=$true}
  @{volunteer_id='TRI-SI-001';full_name='Trincomalee Sinhala Volunteer 01';password='123456';district='17';language='si';active=$true}
)

$pendingUsers = @(
  @{id='33333333-3333-4333-8333-333333333301';phone='+94733330001';nic='200300000001';pin='1234';first_name='Iresha';last_name='Dilrukshi';district='Colombo';ds_area='Colombo';language='si';job_category_ids=@('C04');skill_ids=@('S401','S402');status='pending'}
  @{id='33333333-3333-4333-8333-333333333302';phone='+94733330002';nic='200300000002';pin='1234';first_name='Niroshan';last_name='Kumara';district='05';ds_area='0505';language='si';job_category_ids=@('C03');skill_ids=@('S301');status='pending'}
  @{id='33333333-3333-4333-8333-333333333303';phone='+94733330003';nic='200300000003';pin='1234';first_name='Vijay';last_name='Kumar';district='Jaffna';ds_area='Nallur';language='ta';job_category_ids=@('C10');skill_ids=@('S1001');status='pending'}
  @{id='33333333-3333-4333-8333-333333333304';phone='+94733330004';nic='200300000004';pin='1234';first_name='Rizwana';last_name='Haleem';district='16';ds_area='1608';language='ta';job_category_ids=@('C06');skill_ids=@('S601');status='pending'}
)

$pendingJobs = @(
  @{id='44444444-4444-4444-8444-444444444401';employer_nic='200100000001';employer_name='Sunil Perera';employer_phone='+94710100001';job_title='Small Roofing Repair';job_description='Need roof leak repair before rain.';district='Colombo';ds_area='Colombo';category='Construction & Technical';required_skills='S102, S107';payment='Rs. 15000';language='si';status='pending'}
  @{id='44444444-4444-4444-8444-444444444402';employer_nic='200200000001';employer_name='Arul Kumar';employer_phone='+94720100001';job_title='கடை கணக்குப் பதிவு';job_description='Evening ledger and sales entry support.';district='10';ds_area='1004';category='IT & Clerical';required_skills='S1201';payment='Rs. 2500 per day';language='ta';status='pending'}
  @{id='44444444-4444-4444-8444-444444444403';employer_nic='200100000011';employer_name='Pavithra Madushani';employer_phone='+94710100011';job_title='Village Event Catering';job_description='Need three helpers for serving and cleanup.';district='22';ds_area='2201';category='Events & Catering';required_skills='S1301, S1302';payment='Rs. 5000 each';language='si';status='pending'}
)

$smsMessages = @(
  @{id='sms-demo-001';phone_number='+94733330001';message='REG Iresha 1234';direction='inbound';status='received';created_at='2026-06-17T08:10:00+05:30';sent_at=$null}
  @{id='sms-demo-002';phone_number='+94733330001';message='Registration request received. Volunteer will confirm your area.';direction='outbound';status='sent';created_at='2026-06-17T08:11:00+05:30';sent_at='2026-06-17T08:11:05+05:30'}
  @{id='sms-demo-003';phone_number='+94720100011';message='HELP';direction='inbound';status='received';created_at='2026-06-17T09:00:00+05:30';sent_at=$null}
  @{id='sms-demo-004';phone_number='+94720100011';message='Commands: REG, PROFILE, JOBS, APPLY, POST, HELP';direction='outbound';status='sent';created_at='2026-06-17T09:00:05+05:30';sent_at='2026-06-17T09:00:10+05:30'}
)

$chats = @(
  @{id='direct_200100000001_200200000003';job_id='11111111-1111-4111-8111-111111111101';participant_ids=@('200100000001','200200000003');type='direct';title='House Masonry Repair';last_message='I can visit tomorrow morning.';last_message_time='2026-06-17T10:20:00+05:30'}
  @{id='group_11111111-1111-4111-8111-111111111103';job_id='11111111-1111-4111-8111-111111111103';participant_ids=@('200100000003','200200000010');type='group';title='Deep Cleaning Team';last_message='Advance received, work started.';last_message_time='2026-06-15T10:30:00+05:30'}
)

$chatMessages = @(
  @{id='55555555-5555-4555-8555-555555555501';chat_id='direct_200100000001_200200000003';sender_id='200100000001';text='Can you inspect the wall today?';created_at='2026-06-17T10:00:00+05:30'}
  @{id='55555555-5555-4555-8555-555555555502';chat_id='direct_200100000001_200200000003';sender_id='200200000003';text='I can visit tomorrow morning.';created_at='2026-06-17T10:20:00+05:30'}
  @{id='55555555-5555-4555-8555-555555555503';chat_id='group_11111111-1111-4111-8111-111111111103';sender_id='200100000003';text='Advance sent. Please start with kitchen first.';created_at='2026-06-15T10:10:00+05:30'}
  @{id='55555555-5555-4555-8555-555555555504';chat_id='group_11111111-1111-4111-8111-111111111103';sender_id='200200000010';text='Advance received, work started.';created_at='2026-06-15T10:30:00+05:30'}
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
