import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.170.0/testing/asserts.ts';

Clarinet.test({
    name: "Mint EIP: Identity Creation Test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user = accounts.get('wallet_1')!;

        let block = chain.mineBlock([
            Tx.contractCall('eip-identity', 'create-identity', 
                [types.utf8('test_handle'), types.utf8('Test description')], 
                user.address)
        ]);

        assertEquals(block.receipts.length, 1);
        assertEquals(block.height, 2);
        block.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Mint EIP: Prevent Duplicate Identity Creation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const user = accounts.get('wallet_1')!;

        let block = chain.mineBlock([
            Tx.contractCall('eip-identity', 'create-identity', 
                [types.utf8('test_handle'), types.utf8('Test description')], 
                user.address),
            Tx.contractCall('eip-identity', 'create-identity', 
                [types.utf8('duplicate_handle'), types.utf8('Duplicate description')], 
                user.address)
        ]);

        assertEquals(block.receipts.length, 2);
        block.receipts[0].result.expectOk().expectBool(true);
        block.receipts[1].result.expectErr().expectUint(201); // ERR-IDENTITY-EXISTS
    }
});

Clarinet.test({
    name: "Mint EIP: Identity Update Test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const user = accounts.get('wallet_1')!;

        let block = chain.mineBlock([
            Tx.contractCall('eip-identity', 'create-identity', 
                [types.utf8('initial_handle'), types.utf8('Initial description')], 
                user.address),
            Tx.contractCall('eip-identity', 'update-identity', 
                [types.utf8('updated_handle'), types.utf8('Updated description')], 
                user.address)
        ]);

        assertEquals(block.receipts.length, 2);
        block.receipts[1].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Mint EIP: Attestor Management Test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const attestor = accounts.get('wallet_1')!;

        let block = chain.mineBlock([
            Tx.contractCall('eip-identity', 'add-attestor', 
                [types.principal(attestor.address)], 
                deployer.address)
        ]);

        assertEquals(block.receipts.length, 1);
        block.receipts[0].result.expectOk().expectBool(true);
    }
});