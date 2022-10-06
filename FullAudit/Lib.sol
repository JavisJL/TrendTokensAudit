// SPDX-License-Identifier: ISC
pragma solidity ^0.8.14;

import "./interfaces/IMBNB.sol";

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

    function tokenInPortfolio(IERC20 _bep20, IERC20[] memory _portfolio) internal pure returns(bool) { // finds index of input token
        for (uint i = 0; i < _portfolio.length; i++) {
            if (_portfolio[i] == _bep20) {return true;}
        } return false; // watch out when this is used
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
    
    function allArrayXInArrayY(IERC20[] memory _arrayX, IERC20[] memory _arrayY) internal pure returns(bool) {
        for (uint i=0; i<_arrayX.length; i++) {
            IERC20 token = _arrayX[i];
            bool tokenInVenus = Lib.tokenInPortfolio(token, _arrayY);
            if (tokenInVenus) {}
            else {return false;}
        }
        return true;

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


    /**
    *   consumes manager inputs: portfolio, alloCol, alloBor, and calculated _removedTokens
    *   creates temporary removedTokenPort, removedTokenAlloCol, removedTokenAlloBor for removeTokensRebal
    */
    function ConcatePortX(IERC20[] memory _newPortfolio, IERC20[] memory _removedTokens, uint[] memory _newAllo, uint[] memory _newBorrow) internal pure returns(IERC20[] memory, uint[] memory, uint[] memory) {
        uint newPortLength = _newPortfolio.length + _removedTokens.length;

        IERC20[] memory removedTokenPort = new IERC20[](newPortLength);
        uint[] memory removedTokenAlloCol = new uint[](newPortLength);
        uint[] memory removedTokenAlloBor = new uint[](newPortLength);

        uint i=0; // recreating _newPortfolio in returnArr
        for (; i < _newPortfolio.length; i++) {
            removedTokenPort[i] = _newPortfolio[i];
            removedTokenAlloCol[i] = _newAllo[i];
            removedTokenAlloBor[i] = _newBorrow[i];
        }
        uint j=0; // adding _removedTokens to returnArr
        while (j < _removedTokens.length) {
            removedTokenAlloCol[i] = 0;
            removedTokenAlloBor[i] = 0;
            removedTokenPort[i++] = _removedTokens[j++];
        }
        return (removedTokenPort,removedTokenAlloCol,removedTokenAlloBor);
    } 

    /**
     * used for rebalanceManager() to make sure activePortfolio, alloCollateral and alloBorrow satisfy conditions including: 
     *  activePortfolio, alloCollateral, and alloBorrow all the same length
     *  BUSD is the first in activePortfolio
     *  netEquityPercent = sum(collateral) - sum(borrow) = 10000
     *  long not more than 3x = desiredBorrowBUSD less than 20000
     *  short not more than 1x = borrow (non-BUSD) less than 10000
     */
    function requireAllocationFilter(IERC20[] memory _activePort, uint[] memory _alloCol, uint[] memory _alloBor, uint _DEN) internal pure {
        require(_activePort.length == _alloCol.length && _alloCol.length == _alloBor.length, "Uneven array lengths");
        uint desiredCollateral = 0; // total value of alloCollateral
        uint desiredBorrowBUSD = 0;
        uint desiredBorrowAlt = 0;
        for (uint i=0; i < _activePort.length; i++) {
            desiredCollateral += _alloCol[i];
            if (i==0) {desiredBorrowBUSD += _alloBor[i];}
            else {desiredBorrowAlt += _alloBor[i];}
        }
        //int sumOfAllocations = int(desiredCollateral) - int(desiredBorrowBUSD) - int(desiredBorrowAlt);
        uint netEquityPercent = desiredCollateral - desiredBorrowBUSD - desiredBorrowAlt;
        require(netEquityPercent == _DEN,"col - bor must equal 1."); // equity is equal to 1x
        require(desiredBorrowBUSD <= 2*_DEN,"Must not borrow more than 200% BUSD for leverage long."); //  max 3x long
        require(desiredBorrowAlt <= _DEN,"col - bor must equal 1."); // max 2x short
    }


}