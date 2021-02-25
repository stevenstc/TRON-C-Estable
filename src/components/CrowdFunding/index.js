import React, { Component } from "react";
import Utils from "../../utils";
import contractAddress from "../Contract";

import cons from "../../cons.js";

export default class EarnTron extends Component {
  constructor(props) {
    super(props);

    this.state = {
      texto: "Click to register",
      registrado: false
  

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

      document.getElementById("amount").value = "";

      await Utils.contract.miRegistro(sponsor).send();

    }

    ///// cambiar deposito por egistro en la pagina

    
  };

  render() {

    var {texto} = this.state;
    
    return (
      

        <div>
          <h6 className="text-center">
            Return: <strong>200%</strong><br />
            <strong>2%</strong> per day<br /><br />
          </h6>

          <div className="form-group text-center">
            <input type="text" className="form-control mb-20 text-center" id="amount" placeholder="Min. 200 TRX"></input>
            <p className="card-text">You must have ~ 50 TRX to make the transaction</p>
            <button type="button" className="primary-btn header-btn text-uppercase mb-20 text-center" onClick={() => this.deposit()}>{texto}</button>
          </div>
          
        </div>
      

    );
  }
}
