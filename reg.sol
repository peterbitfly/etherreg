contract Registrar {  
    
    struct Name {
        address target;
        uint auctionExpires;
        uint registrationExpires;
        uint created;
        address owner;
        uint bid;
        uint status;
    }
    
    uint minFee = 1 ether;
    address owner1 = 0x1212;
    address owner2 = 0x1212;
    
    mapping (address => uint) public fees;
    mapping (bytes32 => Name) public names;
    
    event AuctionClosed(bytes32 name, address owner, address target);
    event AuctionStarted(bytes32 name, uint end);
    event OwnerChanged(bytes32 name, address oldOwner, address newOwner);
    event TargetChanged(bytes32 name, address target);
    event RegistrationExtended(bytes32 name, uint newExpiry);
    
    function Register(bytes32 name, address target) {
        
        if (msg.value < minFee)
            throw;
            
        if (names[name].status == 0 || (names[name].status == 2 && now > names[name].registrationExpires)) { // Name not yet registered, start auction
            names[name].status = 1;
            names[name].owner = msg.sender;
            names[name].auctionExpires = now + 7 days; // Auction will last 7 days
            names[name].bid = msg.value;
            names[name].target = target;
            AuctionStarted(name, names[name].auctionExpires);
            return;
        }
        
        if (names[name].status == 1 && now < names[name].auctionExpires && msg.value > names[name].bid) { 
            // Higher bid for the name
            
            // Refund the previous bidder
            names[name].owner.send(names[name].bid);
            
            names[name].owner = msg.sender;
            names[name].bid = msg.value;
            names[name].target = target;
            return;
        }
        
        // Return funds back if nothing can be done
        throw;
    }
    
    function CloseAuction(bytes32 name) { // Claim an address after the auction
    
        if (now > names[name].auctionExpires && names[name].status == 1) {
            names[name].status = 2;
            names[name].registrationExpires = names[name].auctionExpires + 1 years;
            
            fees[owner1] = names[name].bid / 2;
            fees[owner2] = names[name].bid / 2;
            
            AuctionClosed(name, names[name].owner, names[name].target);
            return;
        }
        
        throw;
    }
    
    function ChangeTarget(bytes32 name, address target) {
        if (names[name].owner == msg.sender && names[name].status == 2) {
            names[name].target = target;
            TargetChanged(name, target);
        }
    }
    
    function ChangeOwner(bytes32 name, address owner) {
        if (names[name].owner == msg.sender && names[name].status == 2) {
            OwnerChanged(name, names[name].owner, owner);
            names[name].owner = owner;
        }
    }
    
    function Extend(bytes32 name) { // Allows the owner to extend a registration for another year. An address can only be extended up to 60 days prior to its expiry date
        if (names[name].owner == msg.sender && names[name].status == 2 && now > names[name].registrationExpires - 60 days && msg.value >= names[name].bid) {
            names[name].registrationExpires = names[name].auctionExpires + 1 years;
            RegistrationExtended(name, names[name].registrationExpires);
        }
    }
    
    function WithdrawFee() {
        if (fees[msg.sender] > 0) {
            msg.sender.send(fees[msg.sender]);
            fees[msg.sender] = 0;
        }
    }
    
    function UpdateMinFee(uint newFee) {
        if (msg.sender == owner1 || msg.sender == owner2) {
            minFee = newFee;
        }
    }
}
