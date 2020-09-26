pragma solidity ^0.6.0;

contract DebugBase
{
    event Forwarded(
        address indexed _msgSender,
        address indexed _to,
        bytes _data,
        uint _wei,
        bool _success,
        bytes _resultData);
    function forward(address _to, bytes memory _data)
        public
        payable
        returns (bool, bytes memory)
    {
        (bool success, bytes memory resultData) = _to.call{ value: msg.value }(_data);
        emit Forwarded(msg.sender, _to, _data, msg.value, success, resultData);
        return (success, resultData);
    }

    function blockTimestamp()
        public
        view
        returns (uint256)
    {
        return block.timestamp;
    }
}