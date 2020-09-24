// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "./SafeMath.sol";

interface IERC20 
{
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

contract FlashBot //blockchain based life form 
{
    using SafeMath for uint256;

    address public owner;
    uint public minPerc; // % here is measure in 10,000ths of 1% 
    IERC20[] public checklist; // a list of coins to calculate the product for
    IERC20 public obligateCoin; //== 0xfry_erc20_address

    modifier onlyOwner
    {
        require(msg.sender == owner);
        _;
    }

    constructor(address _owner, IERC20[] memory _checklist)
        payable
    {
        owner = _owner;
        require(checklist[0] == obligateCoin, "c'mon add some $FRY at the front of that bucket!");
        for (uint i = 1; i <= _checklist.length; i++)
        {
            checklist[i] = _checklist[i];
        }
        emit logChecklistChanged(_checklist);
    }

    event logChecklistChanged(IERC20[] _checklist);
    function changeChecklist(IERC20[] calldata _checklist)
        onlyOwner
        public
    {
        for (uint i = 0; i < _checklist.length; i++)
        {
            checklist[i] = _checklist[i];
        }
        emit logChecklistChanged(_checklist);
    }

    function getProduct()
        public
        view
        returns(uint _product)
    {
        _product = address(this).balance;
        for (uint i=0; i < checklist.length; i++)
        {
            _product = _product
                .mul(checklist[i].balanceOf(address(this)))
                .div(checklist[i].decimals());
        }
        require(_product != 0, "i can't work with a product of 0");
    }

    modifier sameState
    {
        // store state in memory
        IERC20 obligateCoinBefore = obligateCoin;
        address ownerBefore = owner;
        uint minPercBefore = minPerc;
        IERC20[] memory checklistBefore;
        for (uint i = 0; i < checklist.length; i++)
        {
            checklistBefore[i] = checklist[i];
        }

        _; //do thing

        //check state to ensure it was not altered in the delegate call
        require(obligateCoinBefore == obligateCoin, "you tried to short change $fry! no weesh!");
        require(ownerBefore == owner, "you tried to change my owner! no weesh!");
        require(minPercBefore == minPerc, "you tried to change my fee! no weesh!");
        for (uint i = 0; i < checklist.length; i++)
        {
            require(checklistBefore[i] == checklist[i], "your tried to tamper with the checklist! no weesh!");
        }
    }

    modifier preservesProduct
    {
        uint productBefore = getProduct();

        _; //do thing

        require(
            msg.sender == owner 
            || productBefore <= getProduct().mul(1e6 + minPerc).div(1e6), 
            "Soz bro, you not the boss of me and you no leave profit for Mr Bot!");
    }

    event logThangDone(address _where, bytes _what);
    function doThang(address _where, bytes calldata _what)
        public
        payable
        sameState
        preservesProduct
        returns (bool _success, bytes memory _result)
    {
        (_success, _result) = _where.delegatecall(_what);
        emit logThangDone(_where, _what);
    }
}
