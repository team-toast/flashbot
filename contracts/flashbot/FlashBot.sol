// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "../common.6/openzeppelin/contracts/math/SafeMath.sol";

interface IERC20 
{
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Forwarder
{
    address public owner;

    constructor(address _owner)
        public
    {
        owner = _owner;
    }

    modifier onlyOwner()
    {
        require(msg.sender == owner, "only owner");
        _;
    }

    event OwnerChanged(address _newOwner);
    function changeOwner(address _newOwner)
        public
        onlyOwner
    {
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }

    event Forwarded(
        address indexed _to,
        bytes _data,
        uint _wei,
        bool _success,
        bytes _resultData);
    function forward(address _to, bytes memory _data, uint _wei)
        public
        onlyOwner
        returns (bool, bytes memory)
    {
        (bool success, bytes memory resultData) = _to.call.value(_wei)(_data);
        emit Forwarded(_to, _data, _wei, success, resultData);
        return (success, resultData);
    }

    // function ()
    //     external
    //     payable
    // { }
}

contract Purse is Forwarder
{
    using SafeMath for uint256;

    uint public minPerc; // % here is measure in 10,000ths of 1% 
    IERC20[] public checklist; // a list of coins to calculate the product for
    mapping(IERC20 => bool) public checklistMap;
    IERC20 public obligateCoin; //== 0xfry_erc20_address
    FlashBot public flashBot;

    constructor(
            address _owner,
            IERC20[] memory _checklist) 
        Forwarder(_owner)
        payable
    {
        setFlashBot(this);
        _changeChecklist(_checklist);
    }

    event logFlashBotChanged(FlashBot _newFlashBot);
    function setFlashBot() 
        public
        onlyOwner
    {
        emit logFlashBotChanged();
        flashBot = _flashBot;
    }

    modifier onlyFlashBot
    {
        require(msg.sender == flashBot);
        _;
    }

    function changeChecklist(IERC20[] calldata _checklist)
        onlyOwner
        public
    {
        _changeChecklist(_checklist);
    }

    event logChecklistChanged(IERC20[] _checklist);
    function _changeChecklist(IERC20[] memory _checklist)
        internal
    {
        require(checklist[0] == obligateCoin, "c'mon add some $FRY at the front of that bucket!");
        for (uint i = 1; i <= _checklist.length; i++)
        {
            checklist[i] = _checklist[i];
        }
        checklist.length = _checklist.length;
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

    event purseTransfer(IERC20 _token, address _recipient, uint _amount);
    function transer(IERC20 _token, address _recipient, uint _amount)
        public
        onlyFlashBot
        returns (bool)
    {
        emit purseTransfer(_token, _recipient, _amount);
        return token.transfer(_recipient, _amount);
    }
}

contract FlashBot //blockchain based life form 
{
    Purse purse;

    constructor(Purse _purse)
    {
        purse = _purse;    
    }

    modifier preservesProduct
    {
        uint productBefore = purse.getProduct();

        _; //do thing

        require(
            msg.sender == owner 
            || productBefore <= purse.getProduct().mul(1e6 + minPerc).div(1e6), 
            "Soz bro, you not the boss of me and you no leave profit for Mr Bot!");
    }

    event logThangDone(address _where, bytes _what);
    function doThang(address _where, bytes calldata _what)
        public
        payable
        preservesProduct
        returns (bool _success, bytes memory _result)
    {
        (_success, _result) = _where.delegatecall(_what);
        emit logThangDone(_where, _what);
    }
}
