// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract PrekiuPirkimas {
    // dalyviai
    address public pardavejas; // = kontrakto savininkas
    address public pirkejas;
    address public kurjeris;

    // prekės duomenys
    string public prekesPav;
    uint public kaina;

    // užsakymo būsena
    enum Busena {
        Neuzsakyta,
        Uzsakyta,
        Patvirtinta,
        Pristatyta, // kurjerio pristatymo patvirtinimas
        Gauta, // kliento gavimo patvirtinimas
        Baigta,
        Atsaukta
    }

    Busena public busena;

    // vykdomas diegiant kontraktą blockchainan
    constructor(string memory _prekesPav, uint _kaina) {
        pardavejas = msg.sender;
        prekesPav = _prekesPav;
        kaina = _kaina;
        busena = Busena.Neuzsakyta;
    }
}
