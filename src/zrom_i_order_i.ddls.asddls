@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View for Restaurant Order Item'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZROM_I_ORDER_I
  as select from zrom_item_t as orderItem
  association to parent ZROM_I_ORDER_H as _orderHeader
    on $projection.OrderId = _orderHeader.OrderId
{
  key orderid                 as OrderId,
  key itemno                  as ItemNo,

      itemname                as ItemName,

      @Semantics.quantity.unitOfMeasure: 'QuantityUnit'  
      quantity                as Quantity,

      quantityunit            as QuantityUnit,           

      @Semantics.amount.currencyCode: 'Currency'
      price                   as Price,

      @Semantics.amount.currencyCode: 'Currency'
      totalamount             as TotalAmount,

      currency                as Currency,

      @Semantics.user.createdBy: true
      local_created_by        as LocalCreatedBy,

      @Semantics.systemDateTime.createdAt: true
      local_created_at        as LocalCreatedAt,

      @Semantics.user.lastChangedBy: true
      local_last_changed_by   as LocalLastChangedBy,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at   as LocalLastChangedAt,

      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at         as LastChangedAt,

      /* Associations */
      _orderHeader
}
