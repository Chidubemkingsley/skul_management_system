// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


// ERC20 interface 

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// ERC20 IMPLEMENTATION for SchoolToken (STKN) - School Currency
contract SchoolToken is IERC20 {
    string public name     = "SchoolToken";
    string public symbol   = "STKN";
    uint8  public decimals = 18;

    uint256 private _totalSupply;

    mapping(address => uint256)                     private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "SchoolToken: not owner");
        _;
    }

    constructor(uint256 initialSupply) {
        owner = msg.sender;
        _mint(msg.sender, initialSupply * 10 ** decimals);
    }

    // ERC20 core 

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address _owner, address spender) external view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "SchoolToken: insufficient allowance");
        unchecked { _allowances[from][msg.sender] = currentAllowance - amount; }
        _transfer(from, to, amount);
        return true;
    }

    // Minting (owner only) 

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // Internal helpers 

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "SchoolToken: transfer from zero address");
        require(to   != address(0), "SchoolToken: transfer to zero address");
        require(_balances[from] >= amount, "SchoolToken: insufficient balance");
        unchecked {
            _balances[from] -= amount;
            _balances[to]   += amount;
        }
        emit Transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "SchoolToken: mint to zero address");
        _totalSupply    += amount;
        _balances[to]   += amount;
        emit Transfer(address(0), to, amount);
    }

    function _approve(address _owner, address spender, uint256 amount) internal {
        require(_owner   != address(0), "SchoolToken: approve from zero address");
        require(spender != address(0), "SchoolToken: approve to zero address");
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
}


// SCHOOL MANAGEMENT SYSTEM CONTRACT

contract SchoolManagementSystem {

    //  ENUMS & STRUCTS

    /// @notice Academic levels (100 – 400)
    enum Level { Level100, Level200, Level300, Level400 }

    /// @notice Payment status for a student's tuition
    enum PaymentStatus { Unpaid, Paid }

    /// @notice Staff status (active or suspended)
    enum StaffStatus { Active, Suspended }

    /// @notice Student status (active or removed)
    enum StudentStatus { Active, Removed }

    struct Student {
        uint256 id;
        string  name;
        string  email;
        Level   level;
        address wallet;
        PaymentStatus paymentStatus;
        uint256 paymentTimestamp;   // 0 if unpaid
        uint256 registeredAt;
        StudentStatus status;       // NEW: Active or Removed
        bool    exists;
    }

    /// @notice Staff role classification
    enum StaffRole { Teacher, Administrator, Support }

    struct Staff {
        uint256   id;
        string    name;
        string    email;
        StaffRole role;
        address   wallet;
        uint256   salary;           //  in STKN (wei units)
        uint256   lastPaidAt;       // timestamp of last salary payment
        uint256   registeredAt;
        StaffStatus status;         // NEW: Active or Suspended
        bool      exists;
    }

   
    //  STATE VARIABLES

    address public admin;
    SchoolToken public token;

    // Tuition fees per level (in STKN wei units) — set at construction
    mapping(Level => uint256) public tuitionFee;

    // Students
    uint256 private _studentIdCounter;
    mapping(uint256 => Student)  private _students;       // id  => Student
    mapping(address => uint256)  private _studentByWallet; // wallet => id

    // Staffs
    uint256 private _staffIdCounter;
    mapping(uint256 => Staff)    private _staffs;
    mapping(address => uint256)  private _staffByWallet;

    
    //  EVENTS

    event StudentRegistered(uint256 indexed id, string name, Level level, address wallet);
    event StudentRemoved(uint256 indexed id, string name, address wallet);      // NEW
    event StaffRegistered(uint256 indexed id, string name, StaffRole role, address wallet);
    event StaffSuspended(uint256 indexed id, string name, StaffRole role);      // NEW
    event StaffActivated(uint256 indexed id, string name, StaffRole role);      // NEW
    event TuitionPaid(uint256 indexed studentId, uint256 amount, uint256 timestamp);
    event SalaryPaid(uint256 indexed staffId, address indexed wallet, uint256 amount, uint256 timestamp);
    event TuitionFeeUpdated(Level level, uint256 newFee);

    
    //  MODIFIERS

    modifier onlyAdmin() {
        require(msg.sender == admin, "SMS: caller is not admin");
        _;
    }

    modifier studentExists(uint256 studentId) {
        require(_students[studentId].exists, "SMS: student not found");
        _;
    }

    modifier staffExists(uint256 staffId) {
        require(_staffs[staffId].exists, "SMS: staff not found");
        _;
    }

    
    //  CONSTRUCTOR

    /**
     * @param _token          Address of the deployed SchoolToken contract
     * @param fee100          Tuition fee for Level 100 (in token wei)
     * @param fee200          Tuition fee for Level 200
     * @param fee300          Tuition fee for Level 300
     * @param fee400          Tuition fee for Level 400
     */
    constructor(
        address _token,
        uint256 fee100,
        uint256 fee200,
        uint256 fee300,
        uint256 fee400
    ) {
        require(_token != address(0), "SMS: zero token address");
        admin = msg.sender;
        token = SchoolToken(_token);

        tuitionFee[Level.Level100] = fee100;
        tuitionFee[Level.Level200] = fee200;
        tuitionFee[Level.Level300] = fee300;
        tuitionFee[Level.Level400] = fee400;
    }

   
    //  ADMIN FUNCTIONS

    /// @notice Update tuition fee for a specific level
    function setTuitionFee(Level level, uint256 newFee) external onlyAdmin {
        tuitionFee[level] = newFee;
        emit TuitionFeeUpdated(level, newFee);
    }

    /// @notice Transfer admin rights
    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "SMS: zero address");
        admin = newAdmin;
    }

    
    //  STUDENT REGISTRATION

    /**
     * @notice Register a new student. Optionally pay tuition at registration.
     * @param name          Student full name
     * @param email         Student email
     * @param level         Academic level (0=100, 1=200, 2=300, 3=400)
     * @param wallet        Student wallet address
     * @param payNow        If true, transfers tuition from msg.sender to contract
     */
    function registerStudent(
        string  calldata name,
        string  calldata email,
        Level   level,
        address wallet,
        bool    payNow
    ) external returns (uint256 studentId) {
        require(bytes(name).length  > 0, "SMS: name required");
        require(bytes(email).length > 0, "SMS: email required");
        require(wallet != address(0),    "SMS: zero wallet");
        require(_studentByWallet[wallet] == 0, "SMS: wallet already registered");

        _studentIdCounter++;
        studentId = _studentIdCounter;

        PaymentStatus status    = PaymentStatus.Unpaid;
        uint256       paidAt    = 0;

        if (payNow) {
            uint256 fee = tuitionFee[level];
            require(fee > 0, "SMS: fee not set for this level");
            bool ok = token.transferFrom(msg.sender, address(this), fee);
            require(ok, "SMS: token transfer failed");
            status = PaymentStatus.Paid;
            paidAt = block.timestamp;
            emit TuitionPaid(studentId, fee, paidAt);
        }

        _students[studentId] = Student({
            id:               studentId,
            name:             name,
            email:            email,
            level:            level,
            wallet:           wallet,
            paymentStatus:    status,
            paymentTimestamp: paidAt,
            registeredAt:     block.timestamp,
            status:           StudentStatus.Active,    // NEW: Default to Active
            exists:           true
        });

        _studentByWallet[wallet] = studentId;

        emit StudentRegistered(studentId, name, level, wallet);
    }

    // NEW: Remove a student from the organisation
    function removeStudent(uint256 studentId) external onlyAdmin studentExists(studentId) {
        Student storage student = _students[studentId];
        require(student.status == StudentStatus.Active, "SMS: student already removed");
        
        student.status = StudentStatus.Removed;
        // Optional: Remove wallet mapping to allow reuse
        // delete _studentByWallet[student.wallet];
        
        emit StudentRemoved(studentId, student.name, student.wallet);
    }

    // NEW: Reactivate a removed student
    function reactivateStudent(uint256 studentId) external onlyAdmin studentExists(studentId) {
        Student storage student = _students[studentId];
        require(student.status == StudentStatus.Removed, "SMS: student is not removed");
        
        student.status = StudentStatus.Active;
        // Optional: Restore wallet mapping if needed
        // _studentByWallet[student.wallet] = studentId;
        
        emit StudentRegistered(studentId, student.name, student.level, student.wallet);
    }

    
    //  STAFF REGISTRATION

    /**
     * @notice Register a new staff member (admin only)
     * @param name    Staff full name
     * @param email   Staff email
     * @param role    StaffRole enum value
     * @param wallet  Staff wallet address
     * @param salary  Monthly salary in STKN wei units
     */
    function registerStaff(
        string    calldata name,
        string    calldata email,
        StaffRole role,
        address   wallet,
        uint256   salary
    ) external onlyAdmin returns (uint256 staffId) {
        require(bytes(name).length  > 0, "SMS: name required");
        require(bytes(email).length > 0, "SMS: email required");
        require(wallet != address(0),    "SMS: zero wallet");
        require(salary > 0,              "SMS: salary must be > 0");
        require(_staffByWallet[wallet] == 0, "SMS: wallet already registered");

        _staffIdCounter++;
        staffId = _staffIdCounter;

        _staffs[staffId] = Staff({
            id:           staffId,
            name:         name,
            email:        email,
            role:         role,
            wallet:       wallet,
            salary:       salary,
            lastPaidAt:   0,
            registeredAt: block.timestamp,
            status:       StaffStatus.Active,    // NEW: Default to Active
            exists:       true
        });

        _staffByWallet[wallet] = staffId;

        emit StaffRegistered(staffId, name, role, wallet);
    }

    // NEW: Suspend a staff member
    function suspendStaff(uint256 staffId) external onlyAdmin staffExists(staffId) {
        Staff storage staff = _staffs[staffId];
        require(staff.status == StaffStatus.Active, "SMS: staff is already suspended");
        
        staff.status = StaffStatus.Suspended;
        
        emit StaffSuspended(staffId, staff.name, staff.role);
    }

    // NEW: Activate a suspended staff member
    function activateStaff(uint256 staffId) external onlyAdmin staffExists(staffId) {
        Staff storage staff = _staffs[staffId];
        require(staff.status == StaffStatus.Suspended, "SMS: staff is not suspended");
        
        staff.status = StaffStatus.Active;
        
        emit StaffActivated(staffId, staff.name, staff.role);
    }

    
    //  PAYMENT FUNCTIONS

    /**
     * @notice Pay tuition for an already-registered student.
     *         Caller must have approved this contract to spend STKN.
     * @param studentId  The student's ID
     */
    function payTuition(uint256 studentId) external studentExists(studentId) {
        Student storage s = _students[studentId];
        require(s.status == StudentStatus.Active, "SMS: student is not active");  // UPDATED: Check if active
        require(s.paymentStatus == PaymentStatus.Unpaid, "SMS: tuition already paid");

        uint256 fee = tuitionFee[s.level];
        require(fee > 0, "SMS: fee not set for this level");

        bool ok = token.transferFrom(msg.sender, address(this), fee);
        require(ok, "SMS: token transfer failed");

        s.paymentStatus    = PaymentStatus.Paid;
        s.paymentTimestamp = block.timestamp;

        emit TuitionPaid(studentId, fee, block.timestamp);
    }

    /**
     * @notice Pay a staff member's salary (admin only).
     *         Contract must hold sufficient STKN balance.
     * @param staffId  The staff member's ID
     */
    function payStaff(uint256 staffId) external onlyAdmin staffExists(staffId) {
        Staff storage st = _staffs[staffId];
        require(st.status == StaffStatus.Active, "SMS: staff is not active");  // UPDATED: Check if active

        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance >= st.salary, "SMS: insufficient contract balance");

        bool ok = token.transfer(st.wallet, st.salary);
        require(ok, "SMS: salary transfer failed");

        st.lastPaidAt = block.timestamp;

        emit SalaryPaid(staffId, st.wallet, st.salary, block.timestamp);
    }

   
    //  QUERY FUNCTIONS — STUDENTS

    /// @notice Get full details of a single student by ID
    function getStudent(uint256 studentId)
        external
        view
        studentExists(studentId)
        returns (Student memory)
    {
        return _students[studentId];
    }

    /// @notice Look up a student by their wallet address
    function getStudentByWallet(address wallet)
        external
        view
        returns (Student memory)
    {
        uint256 id = _studentByWallet[wallet];
        require(id != 0, "SMS: student not found for wallet");
        return _students[id];
    }

    /// @notice Get all registered students (including removed)
    function getAllStudents() external view returns (Student[] memory) {
        Student[] memory result = new Student[](_studentIdCounter);
        for (uint256 i = 1; i <= _studentIdCounter; i++) {
            result[i - 1] = _students[i];
        }
        return result;
    }

    /// @notice Get total number of registered students
    function totalStudents() external view returns (uint256) {
        return _studentIdCounter;
    }

    
    //  QUERY FUNCTIONS — STAFF

    /// @notice Get full details of a single staff member by ID
    function getStaff(uint256 staffId)
        external
        view
        staffExists(staffId)
        returns (Staff memory)
    {
        return _staffs[staffId];
    }

    /// @notice Look up a staff member by wallet address
    function getStaffByWallet(address wallet)
        external
        view
        returns (Staff memory)
    {
        uint256 id = _staffByWallet[wallet];
        require(id != 0, "SMS: staff not found for wallet");
        return _staffs[id];
    }

    /// @notice Get all registered staff members (including suspended)
    function getAllStaff() external view returns (Staff[] memory) {
        Staff[] memory result = new Staff[](_staffIdCounter);
        for (uint256 i = 1; i <= _staffIdCounter; i++) {
            result[i - 1] = _staffs[i];
        }
        return result;
    }

    /// @notice Get total number of registered staff members
    function totalStaff() external view returns (uint256) {
        return _staffIdCounter;
    }

    
    //  UTILITY
    

    /// @notice Returns the tuition fee for every level in one call
    function getAllTuitionFees()
        external
        view
        returns (
            uint256 fee100,
            uint256 fee200,
            uint256 fee300,
            uint256 fee400
        )
    {
        return (
            tuitionFee[Level.Level100],
            tuitionFee[Level.Level200],
            tuitionFee[Level.Level300],
            tuitionFee[Level.Level400]
        );
    }

    /// @notice Check the STKN balance held by this contract (school treasury)
    function treasuryBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
}