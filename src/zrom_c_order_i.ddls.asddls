@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Restaurant Order Item Consumption View'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZROM_C_ORDER_I
  as projection on ZROM_I_ORDER_I
{
  key OrderId,
  key ItemNo,

      ItemName,

      @Semantics.quantity.unitOfMeasure: 'QuantityUnit' 
      Quantity,

      QuantityUnit,                                     
      @Semantics.amount.currencyCode: 'Currency'
      Price,

      @Semantics.amount.currencyCode: 'Currency'
      TotalAmount,

      Currency,

      LocalCreatedBy,
      LocalCreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,

      /* Associations */
      _orderHeader : redirected to parent ZROM_C_ORDER_H
}
