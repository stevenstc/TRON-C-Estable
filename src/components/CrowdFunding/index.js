import React, { Component } from "react";
import Utils from "../../utils";
import contractAddress from "../Contract";

import cons from "../../cons.js";

export default class EarnTron extends Component {
  constructor(props) {
    super(props);

    this.state = {
      texto: "Click to register",
      registrado: false,
      min: 200
  

    };

    this.deposit = this.deposit.bind(this);
    this.estado = this.estado.bind(this);
  }

  async componentDidMount() {
    await Utils.setContract(window.tronWeb, contractAddress);
    this.estado();
    setInterval(() => this.estado(),3*1000);
  };

  async estado(){

    const account =  await window.tronWeb.trx.getAccount();
    var accountAddress = account.address;
    accountAddress = window.tronWeb.address.fromHex(accountAddress);
    var investors = await Utils.contract.investors(accountAddress).call();

    if (!investors.registered) {
      document.getElementById("amount").value = "";
      this.setState({
        texto:"Click to register",
        registrado: false
      });
    }else{

      this.setState({
        texto:"Invest",
        registrado: true
      });

    }

    var min = await Utils.contract.MIN_DEPOSIT().call();

    min = parseInt(min._hex)/1000000;


    var tarifa = await Utils.contract.tarifa().call();

    tarifa = parseInt(tarifa._hex);

    this.setState({
      min: min,
      tarifa: tarifa
    });

    //console.log(min);

    

  }


  async deposit() {

    const {registrado} = this.state;


    var amount = document.getElementById("amount").value;


    if (registrado) {

      await Utils.contract.deposit().send({
        shouldPollResponse: true,
        callValue: amount * 1000000 // converted to SUN
      });

      document.getElementById("amount").value = "";

    }else{

      document.getElementById("amount").value = "";

      var loc = document.location.href;
      if(loc.indexOf('?')>0){
          var getString = loc.split('?')[1];
          var GET = getString.split('&');
          var get = {};
          for(var i = 0, l = GET.length; i < l; i++){
              var tmp = GET[i].split('=');
              get[tmp[0]] = unescape(decodeURI(tmp[1]));
          }
          
          if (get['ref']) {
            tmp = get['ref'].split('#');
            var inversors = await Utils.contract.investors(tmp[0]).call();
            console.log(inversors);
            if ( inversors.registered && inversors.exist ) {
              document.getElementById('sponsor').value = tmp[0]; 
            }else{
              document.getElementById('sponsor').value = cons.WS;         
            }
          }else{
             document.getElementById('sponsor').value = cons.WS;
          }
             
      }else{
        
          document.getElementById('sponsor').value = cons.WS; 
      }

      let sponsor = document.getElementById("sponsor").value;

      await Utils.contract.register(sponsor).send();

    }


    
  };


  render() {

    var { texto, min, tarifa} = this.state;

    min = "Min. "+min+" TRX";

    switch (tarifa) 
        {
            case 0:  tarifa = 2;
                     break;
            case 1:  tarifa = 3;
                     break;
            case 2:  tarifa = 4;
                     break;
            case 3:  tarifa = 6;
                     break;
            
            default: tarifa = "N/A";
                     break;
        }


      

    
    return (
      

        <div>
          <h6 className="text-center">
            Return: <strong>{tarifa}00%</strong><br />
            <strong>{tarifa}%</strong> per day<br /><br />
          </h6>

          <div className="form-group text-center">
            <input type="text" className="form-control mb-20 text-center" id="amount" placeholder={min}></input>
            <p className="card-text">You must have ~ 50 TRX to make the transaction</p>
            
            <button type="button" style={{'margin-right': '3.8em'}} className="primary-btn header-btn text-uppercase mb-20 text-center" onClick={() => this.deposit()}>{texto}</button>
          </div>
          
        </div>
      

    );
  }
}
