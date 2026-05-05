# Seeded Database Data

This file records the demo data that was pushed to the hosted Render backend at `https://informal-worker.onrender.com`.

## Summary

- Workers registered: 10
- Jobs created: 12
- Demo login verified: Yes
- Demo credentials: `200011111111 / 1234`

## Seeded Workers

| NIC | Name | Phone | District | DS Area | Categories | Skills | Rating | Completed Jobs |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 200011111111 | Colombo Worker | 0711111111 | Colombo | Colombo | C01, C05 | S101, S501, S502 | 4.8 | 15 |
| 200022222222 | Kasun Electrician | 0722222222 | Gampaha | Gampaha | C05 | S501, S502, S505 | 4.6 | 22 |
| 200033333333 | Kumari Housekeeper | 0733333333 | Kalutara | Kalutara | C04, C06 | S401, S402, S403, S601 | 4.9 | 38 |
| 200044444444 | Ravi Driver | 0744444444 | Kandy | Akurana | C02 | S201, S202, S203 | 4.7 | 42 |
| 200055555555 | Samantha Farmer | 0755555555 | Matale | Matale | C03 | S301, S302, S303 | 4.4 | 18 |
| 200066666666 | Anura Chef | 0766666666 | Nuwara Eliya | Nuwara Eliya | C06, C13 | S601, S602, S603, S1301 | 4.5 | 20 |
| 200077777777 | Priya Beautician | 0777777777 | Galle | Galle | C07 | S701, S702, S703 | 4.9 | 52 |
| 200088888888 | Dinesh Plumber | 0788888888 | Matara | Matara | C05 | S502, S503, S505 | 4.6 | 31 |
| 200099999999 | Thulani Artist | 0799999999 | Hambantota | Hambantota | C08 | S801, S802, S803, S804 | 4.3 | 12 |
| 200010101010 | Amara Shopkeeper | 0701010101 | Jaffna | Jaffna | C10, C12 | S1001, S1002, S1003, S1201 | 4.5 | 25 |

## Seeded Jobs

| Title | Employer NIC | Area | Skills Needed | Status |
| --- | --- | --- | --- | --- |
| Home Renovation & Repair | 200011111111 | Colombo | S101, S102 | open |
| Electrical Installation | 200022222222 | Gampaha | S501 | open |
| Full House Cleaning Service | 200033333333 | Kalutara | S401, S402, S403 | open |
| Delivery & Transportation | 200044444444 | Kandy | S202, S203 | open |
| Agricultural Work - Tea Plantation | 200055555555 | Matale | S303 | open |
| Event Catering & Food Preparation | 200066666666 | Nuwara Eliya | S601, S1301 | open |
| Salon Services - Hair & Beauty | 200077777777 | Galle | S701, S702 | open |
| Plumbing & Water System Installation | 200088888888 | Matara | S502 | open |
| Interior Design & Decoration | 200099999999 | Hambantota | S803 | open |
| Retail Shop Management | 200010101010 | Jaffna | S1001 | open |
| Office Painting | 200011111111 | Colombo | S104 | completed |
| Bathroom Renovation | 200022222222 | Gampaha | S501 | completed |

## Demo Login

- NIC: `200011111111`
- PIN: `1234`
- Status: confirmed working against Render backend

## Notes

- The backend required `language` during registration, so the seeded workers were registered with `language = en`.
- Login responses from Render return `access_token`.
- The seed script creates the 10 workers first, then creates the 12 jobs using the authenticated demo account.
- The application list in the seed service is simulated in logs only and is not persisted through a separate API call.
