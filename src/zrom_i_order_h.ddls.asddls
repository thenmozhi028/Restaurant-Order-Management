@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Restaurant Order Header'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZROM_I_ORDER_H
  as select from zrom_header_t as orderHeader
  composition [0..*] of ZROM_I_ORDER_I as _orderItems
{
  key orderid                 as OrderId,
      customername            as CustomerName,
      tableno                 as TableNo,
      orderstatus             as OrderStatus,
      orderdate               as OrderDate,
      ordertime               as OrderTime,

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
      _orderItems
}
