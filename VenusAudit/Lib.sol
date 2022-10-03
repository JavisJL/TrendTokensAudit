// SPDX-License-Identifier: ISC
pragma solidity ^0.8.14;


library Lib { // deployed at: 0x92EB22eb4f4dFE719a988F328cE88ce36DD5279A

    // Contastants 
    uint public constant PRICE_DEN = 1e18;

    // -----   PancakeSwap ----------- //

    function pathGenerator2(address coinIn, address coinOut) internal pure returns(address[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(coinIn);
        path[1] = address(coinOut);
        return path;
    }

    function pathGenerator3(address _coinIn, address _interRoute1, address _coinOut) internal pure returns(address[] memory) {
        address[] memory path = new address[](3);
        path[0] = address(_coinIn);
        path[1] = address(_interRoute1);
        path[2] = address(_coinOut);
        return path;
    }

    function getValue(uint256 _amount, uint256 _price) internal pure returns(uint256) {
        return _amount * _price / PRICE_DEN;
    }

    function getAssetAmt(uint256 _usdAmount, uint256 _price) internal pure returns(uint256) {
        return _usdAmount * PRICE_DEN / _price;
    }

    // -------- UTILITY FUNCTIONS ------------- //

    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        return b >= a ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns(uint256) {
        return b >= a ? b : a;
    }

    function abs(int256 x) internal pure returns (uint256) {
        return x >= 0 ? uint256(x) : uint256(-x);
    }

    /**
    *   Makes sure value is within valueA and valueB
    */
    function isWithinRange(uint value, uint valueA, uint valueB) internal pure returns(bool) {
        // require high > low
        // require 
        
    }


    function countValueArray(uint[] memory _array) internal pure returns(uint) {
        uint sum;
        for(uint i=0; i<_array.length; i++) { sum += _array[i];}
        return sum;
    }

    function reverseArray(address[] memory _array) internal pure returns(address[] memory) {
        uint length = _array.length;
        address[] memory reversedArray = new address[](length);
        uint j = 0;
        for(uint i = length; i >= 1; i--) {
            reversedArray[j] = _array[i-1];
            j++;
        }
        return reversedArray;
    }

    function reverseArrayUint(uint[] memory _array) internal pure returns(uint[] memory) {
        uint length = _array.length;
        uint[] memory reversedArray = new uint[](length);
        uint j = 0;
        for(uint i = length; i >= 1; i--) {
            reversedArray[j] = _array[i-1];
            j++;
        }
        return reversedArray;
    }
    

    function setRequire(uint _value, uint low, uint high, string memory _message) internal pure {
        require(_value >= low && _value <= high, _message);
    }

    function maxRequire(uint _value, uint _max, string memory _message) internal pure {
        require(_value <= _max, _message);
    }

    function minRequire(uint _value, uint _min, string memory _message) internal pure {
        require(_value >= _min, _message);
    }



}