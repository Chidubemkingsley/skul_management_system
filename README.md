# SchoolManagementSystem Contract Assignment

- REQUIREMENTS
```
Create a School management system where people can:
* Register students & Staffs.
* Pay School fees on registration.
* Pay staffs also.
* Get the students and their details.
* Get all Staffs.
* Pricing is based on grade / levels from 100 - 400 level.
* Payment status can be updated once the payment is made which should include the timestamp.
```

## BREAKDOWN
- With transfer, transferFrom, approve, allowance, and an owner-gated mint function. The school uses this token as its internal currency.

```
SchoolToken (STKN) — ERC20
```

- Students carry:
``` 
ID, name, email, level (100–400), wallet, PaymentStatus (Unpaid/Paid), paymentTimestamp, and registeredAt.
```
- Staff carry: 
```
ID, name, email, StaffRole (Teacher/Administrator/Support), wallet, salary, lastPaidAt, and registeredAt.
```

## WORKTHROUGH WITH REMIX IDE.


When deploying SchoolToken, the initialSupply parameter is just the whole number of tokens you want — the contract handles multiplying by 10**18 internally.

```soliditY
_mint(msg.sender, initialSupply * 10 ** decimals);
```

### Step by step in Remix:

1. DEPLOY THE SchoolToken contract
- Select SchoolToken from the contract dropdown
- In the VALUE field at the top → set it to 0 and unit to Wei
- In the Deploy input box next to the button → type 1000000
- Click Deploy
```
status:            Transaction mined and execution succeed
contract address: 0xd9145CCE52D386f254917e481eB44e9943F39138
from (admin):     0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
tokens minted:    1,000,000,000,000,000,000,000,000 wei = 1,000,000 STKN 
```

### Click balanceOf In SchoolToken contract
- Paste your wallet address this time:
```
0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
```
- Click call

- You should then see:
```
uint256: 1000000000000000000000000
```

2. Deploy SchoolManagementSystem

- The _token parameter is `0xd9145CCE52D386f254917e481eB44e9943F39138` — the SchoolToken contract address.
-  Click Deploy
```
0xd9145CCE52D386f254917e481eB44e9943F39138, 
100000000000000000000 
200000000000000000000 
300000000000000000000 
400000000000000000000
```

### Both contracts are deployed successfully! 

- SchoolToken:            `0xd9145CCE52D386f254917e481eB44e9943F39138`
- SchoolManagementSystem: `0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8`

### Go to the deployed SchoolToken contract and call approve with:
- spender:  `0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8`
- amount:   `1000000000000000000000000`
`This allows the school contract to pull tokens from your wallet when students pay fees`
```
Approved:  1,000,000 STKN 
Owner:     0x5B38...C4  (your wallet)
Spender:   0xd8b9...fa8 (SchoolManagementSystem) 
```
### After that approval you can start using the system:
#### Register a Student:
- On SchoolManagementSystem → registerStudent:
- name:    "Chidubem"
- email:   "chidubem@gmail.com"
- level:   0 (0=Level100, 1=Level200, 2=Level300, 3=Level400)
- wallet:  `0x5B38Da6a701c568545dCfcB03FcB875f56beddC4`
- payNow:  true
```
studentId:        1 
Name:             Chidubem 
Level:            100 
Wallet:           0x5B38...C4 

Transfer Event:
  From:   0x5B38...C4  (your wallet)
  To:     0xd8b9...fa8 (school treasury)
  Amount: 100 STKN 

TuitionPaid Event:
  studentId:  1 
  Amount:     100 STKN 
  Timestamp:  1771476914 

StudentRegistered Event:
  studentId:  1 
  Name:       Chidubem 
```

- Go to SchoolManagementSystem → find registerStaff and fill in:
- name:    "Mr Damilare"
- email:   "adeleke@school.com"
- role:    0
- wallet:  0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
- salary:  50000000000000000000
## Role options:
- 0 = Teacher // if registering for a teacher
- 1 = Administrator //if registering for an admin
- 2 = Support // if register for support
Salary breakdown:
50000000000000000000 = 50 STKN per pay cycle;

- Can call setTuitionFee to set TuitionFee:
level:   0
newFee:  100000000000000000000

- Go to SchoolToken contract (not SchoolManagementSystem) → find transfer and fill in:
to:      `0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8`
amount:  `500000000000000000000000`

- Treasury balance(SchoolManagementSystem topped up successfully!) 
From:    0x5B38...C4  (your wallet)
To:      0xd8b9...fa8 (school treasury)
Amount:  500,000 STKN 
- Treasury balance is now:
 100 STKN    (from John's tuition)
+ 500,000 STKN (top up)
= 500,100 STKN total 

- transferAdmin transfers ownership of the school to a new admin address.

- Go to SchoolManagementSystem → transferAdmin and fill in:
- newAdmin:  0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
- That's one of Remix's default test accounts — a different address from your current admin.

- What this does:
Current admin:  0x5B38...C4   (loses admin rights)
New admin:      0xAb84...cb2  (gains admin rights)

```
Admin transferred successfully! 
Previous admin:  0x5B38...C4  (no longer admin)
New admin:       0xAb84...cb2 

Important — Switch your account now to the new Admin
```
- To verify the transfer worked, call admin on SchoolManagementSystem — it should return:
```
0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 
```

