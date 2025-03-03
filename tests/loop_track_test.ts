import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test activity logging with authorization",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const user1 = accounts.get('wallet_1')!;
    
    // Log activity
    let block = chain.mineBlock([
      Tx.contractCall('loop-track', 'log-activity',
        [
          types.ascii("running"),
          types.uint(30),
          types.uint(300)
        ],
        user1.address
      )
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Check stats
    let response = chain.callReadOnlyFn(
      'loop-track',
      'get-user-stats',
      [types.principal(user1.address)],
      user1.address
    );
    
    let stats = response.result.expectOk().expectSome();
    assertEquals(stats['total-activities'], types.uint(1));
    assertEquals(stats['total-duration'], types.uint(30));
    assertEquals(stats['total-calories'], types.uint(300));
  }
});

// Additional test cases for invalid activities and calories
Clarinet.test({
  name: "Test invalid activity type rejection",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const user1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('loop-track', 'log-activity',
        [
          types.ascii("invalid_activity"),
          types.uint(30),
          types.uint(300)
        ],
        user1.address
      )
    ]);
    
    block.receipts[0].result.expectErr(types.uint(101));
  }
});
