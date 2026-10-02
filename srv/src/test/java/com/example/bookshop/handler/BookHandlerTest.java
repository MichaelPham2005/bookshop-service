package com.example.bookshop.handler;

import static org.junit.jupiter.api.Assertions.assertEquals;

import cds.gen.bookshop.management.Inventory;
import java.math.BigDecimal;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

class BookHandlerTest {

  @ParameterizedTest
  @CsvSource({
    "0,0,5,20,Out of Stock,1,20,0.00",
    "6,2,5,20,Low Stock,2,16,39.96",
    "15,2,5,20,In Stock,3,7,129.87",
    "30,2,5,20,Overstock,2,0,279.72"
  })
  void updateDerivedInventory_StockPosition_ComputesStatusAndMeasures(
      int onHand,
      int reserved,
      int reorderPoint,
      int targetStock,
      String expectedStatus,
      int expectedCriticality,
      int expectedSuggestedQuantity,
      BigDecimal expectedValue) {
    Inventory inventory = Inventory.create();
    inventory.setOnHand(onHand);
    inventory.setReserved(reserved);
    inventory.setReorderPoint(reorderPoint);
    inventory.setTargetStock(targetStock);

    BookHandler.updateDerivedInventory(inventory, new BigDecimal("9.99"));

    assertEquals(onHand - reserved, inventory.getAvailable());
    assertEquals(expectedStatus, inventory.getInventoryStatus());
    assertEquals(expectedCriticality, inventory.getInventoryStatusCriticality());
    assertEquals(expectedSuggestedQuantity, inventory.getSuggestedRestockQuantity());
    assertEquals(0, expectedValue.compareTo(inventory.getInventoryValue()));
    assertEquals("USD", inventory.getCurrency());
  }
}
