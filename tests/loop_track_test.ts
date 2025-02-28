import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test activity logging and rewards",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const user1 = accounts.get('wallet_1')!;
    
    // Log activity
    let block = chain.mineBlock([
      Tx.contractCall('loop-track', 'log-activity',
        [
          types.principal(user1.address),
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

Clarinet.test({
  name: "Test goal setting and tracking",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const user1 = accounts.get('wallet_1')!;
    
    // Set goal
    let block = chain.mineBlock([
      Tx.contractCall('loop-track', 'set-goal',
        [
          types.principal(user1.address),
          types.ascii("running"),
          types.uint(1000)
        ],
        user1.address
      )
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Check goal
    let response = chain.callReadOnlyFn(
      'loop-track',
      'get-user-goals',
      [types.principal(user1.address)],
      user1.address
    );
    
    let goals = response.result.expectOk().expectSome();
    assertEquals(goals['activity-type'], "running");
    assertEquals(goals['target-duration'], types.uint(1000));
    assertEquals(goals['completed'], false);
  }
});

Clarinet.test({
  name: "Test reward transfers",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const user1 = accounts.get('wallet_1')!;
    const user2 = accounts.get('wallet_2')!;
    
    // Log activity to earn rewards
    let block = chain.mineBlock([
      Tx.contractCall('loop-track', 'log-activity',
        [
          types.principal(user1.address),
          types.ascii("running"),
          types.uint(100),
          types.uint(500)
        ],
        user1.address
      )
    ]);
    
    // Transfer rewards
    block = chain.mineBlock([
      Tx.contractCall('loop-track', 'transfer-rewards',
        [
          types.uint(3),
          types.principal(user1.address),
          types.principal(user2.address)
        ],
        user1.address
      )
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Check balances
    let response = chain.callReadOnlyFn(
      'loop-track',
      'get-reward-balance',
      [types.principal(user2.address)],
      user2.address
    );
    
    response.result.expectOk().expectUint(3);
  }
});
