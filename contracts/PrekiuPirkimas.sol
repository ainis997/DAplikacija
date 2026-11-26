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

    // kontraktan sumokėta suma (wei'ais)
    uint public sumoketaSuma;

    // vykdomas diegiant kontraktą blockchainan
    constructor(string memory _prekesPav, uint _kaina) {
        pardavejas = msg.sender;
        prekesPav = _prekesPav;
        kaina = _kaina;
        busena = Busena.Neuzsakyta;
    }

    // ĮVYKIAI

    event PrekeNupirkta(address indexed pirkejas, uint suma);
    event UzsakymasPatvirtintas(address indexed kurjeris);
    event PristatymasPatvirtintas();
    event GavimasPatvirtintas();
    event UzsakymasAtsauktas();

    // MODIFIERIAI

    modifier TikPardavejas() {
        require(
            msg.sender == pardavejas,
            unicode"Funkciją gali kviesti tik pardavėjas."
        );
        _; // čia reiškia, kad nuo čia toliau eis modifikuotos fjos kodas (jei viskas ok)
    }

    modifier TikPirkejas() {
        require(
            msg.sender == pirkejas,
            unicode"Funkciją gali kviesti tik pirkėjas."
        );
        _;
    }

    modifier TikKurjeris() {
        require(
            msg.sender == kurjeris,
            unicode"Funkciją gali kviesti tik kurjeris."
        );
        _;
    }

    // FUNKCIJOS

    function pirktPreke() external payable {
        pirkejas = msg.sender;
        sumoketaSuma = msg.value;
        busena = Busena.Uzsakyta;

        emit PrekeNupirkta(pirkejas, sumoketaSuma);
    }

    function patvirtintUzsakyma(address _kurjeris) external TikPardavejas {
        kurjeris = _kurjeris;
        busena = Busena.Patvirtinta;

        emit UzsakymasPatvirtintas(kurjeris);
    }

    function patvirtintPristatyma() external TikKurjeris {
        busena = Busena.Pristatyta;

        emit PristatymasPatvirtintas();
    }

    function patvirtintGavima() external TikPirkejas {
        busena = Busena.Gauta;
        // pardavėjui išmokėt pinigus

        emit GavimasPatvirtintas();
    }

    function atsauktUzsakyma() external TikPirkejas /** o pardavėjas? */ {
        busena = Busena.Atsaukta;
        // pirkėjui išmokėt pinigus

        emit UzsakymasAtsauktas();
    }
}
