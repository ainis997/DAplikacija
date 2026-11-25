// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract PrekiuPirkimas {
    address public savininkas; // = pardavėjas
    // ...

    constructor() {
        savininkas = msg.sender;
    }
}
