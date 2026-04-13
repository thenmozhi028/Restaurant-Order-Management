@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Restaurant Order Header Consumption View'
@Search.searchable: true
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity ZROM_C_ORDER_H
  provider contract transactional_query
  as projection on ZROM_I_ORDER_H
{
  key OrderId,

      @Search.defaultSearchElement: true
      CustomerName,

      @Search.defaultSearchElement: true
      TableNo,

      OrderStatus,
      OrderDate,
      OrderTime,

      @Semantics.amount.currencyCode: 'Currency'
      TotalAmount,
      Currency,

      LocalCreatedBy,
      LocalCreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,

      /* Associations */
      _orderItems : redirected to composition child ZROM_C_ORDER_I
}
