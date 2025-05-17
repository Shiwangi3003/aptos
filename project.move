module MyModule::TokenSwap {
    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use std::error;
    
    /// Error codes
    const E_INSUFFICIENT_BALANCE: u64 = 1;
    const E_SWAP_NOT_AVAILABLE: u64 = 2;
    
    /// Struct representing a swap offer
    struct SwapOffer has key, store {
        token_amount: u64,    // Amount of tokens offered for swap
        rate: u64,            // Exchange rate (in basis points, 10000 = 1:1)
        is_active: bool       // Whether the swap offer is active
    }
    
    /// Function to create a new swap offer
    public entry fun create_swap_offer(
        creator: &signer,
        token_amount: u64,
        rate: u64
    ) {
        // Create the swap offer
        let offer = SwapOffer {
            token_amount,
            rate,
            is_active: true
        };
        
        // Move the offer to creator's account
        move_to(creator, offer);
    }
    
    /// Function to perform a token swap
    public entry fun perform_swap(
        swapper: &signer,
        creator_address: address,
        swap_amount: u64
    ) acquires SwapOffer {
        // Get the swap offer
        let offer = borrow_global_mut<SwapOffer>(creator_address);
        
        // Check if offer is active
        assert!(offer.is_active, error::invalid_state(E_SWAP_NOT_AVAILABLE));
        
        // Check if there are enough tokens to swap
        assert!(offer.token_amount >= swap_amount, error::invalid_argument(E_INSUFFICIENT_BALANCE));
        
        // Calculate the amount to be paid by the swapper based on the rate
        let payment_amount = (swap_amount * offer.rate) / 10000;
        
        // Transfer tokens from swapper to creator
        let coins_to_creator = coin::withdraw<AptosCoin>(swapper, payment_amount);
        coin::deposit(creator_address, coins_to_creator);
        
        // Update the swap offer
        offer.token_amount = offer.token_amount - swap_amount;
        
        // If all tokens are swapped, deactivate the offer
        if (offer.token_amount == 0) {
            offer.is_active = false;
        }
    }
}
