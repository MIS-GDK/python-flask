CREATE OR REPLACE PACKAGE BODY HRHNPROD.Hn_Po_Plan_Source_Pkg IS

  FUNCTION Get_Jsonnumber(Get_Json Json, Dataname IN VARCHAR2)
    RETURN VARCHAR2 IS
  BEGIN
    RETURN Nvl(Json_Ext.Get_Number(Get_Json, Dataname),
               Json_Ext.Get_String(Get_Json, Dataname));
  END;

  /***
  计划订单取数来源
  ***/
  PROCEDURE Po_Plan_Source_Data_Sp(p_Entryid IN NUMBER DEFAULT 9,
                                   p_Goodsid IN NUMBER DEFAULT NULL) IS
    CURSOR Goods_Cur IS
      SELECT *
        FROM Po_Plan_Source_Data_Tl s
       WHERE s.Entryid = p_Entryid
         AND s.Goodsid = Nvl(p_Goodsid, s.Goodsid);
  
    v_Count        NUMBER;
    v_Sales_Order  NUMBER; --近三月销售订单条目数
    v_Sales_Count1 NUMBER; --近三月销量1
    v_Sales_Count2 NUMBER; --近三月销量2
    v_Sales_Count3 NUMBER; --近三月销量3
  
    --v_Last_Sales_Count NUMBER; --去年同期销量 
    --v_Last_Po_Count    NUMBER; --去年同期采购量
    v_Po_In  NUMBER; --去年同期采购进货量
    v_Po_Out NUMBER; --去年同期采购退货量
    --v_Avg_Po_Count     NUMBER; --月均采购量
  
    v_Current_Sales_Count NUMBER; --本月已销量
    v_Avg_Sales_Count     NUMBER; --月平均销量
  
    v_Goodsqty     NUMBER; --当前库存
    v_Goodsqty_Use NUMBER; --可销库存
    --v_Plan_Qty     NUMBER; --当日计划
    v_Online_Qty NUMBER; --15天在途数量
  
    v_Supplyid   VARCHAR2(32767);
    v_Supplyname VARCHAR2(32767);
  
    v_Exists_Conversion NUMBER; --是否存在转换表中
  BEGIN
    IF p_Goodsid IS NULL THEN
      EXECUTE IMMEDIATE 'truncate table Po_Plan_Source_Data_Tl';
    ELSE
      DELETE FROM Po_Plan_Source_Data_Tl s
       WHERE s.Entryid = p_Entryid
         AND s.Goodsid = p_Goodsid;
    END IF;
    --插入符合基本条件的货品信息
    INSERT INTO Po_Plan_Source_Data_Tl
      (Entryid,
       Goodsno, --货品编码
       Goodsid, --货品ID
       Goodsname, --通用名
       Currencyname, --商品名
       Goodstype, --规格
       Goodsunit, --最小单位
       Large_Tranfer_Rate, --件比
       Supplytaxrate, --税率
       Price_Tax, -- 含税进价
       Price_Hosp, --医院限制价格
       Goodsmemo, --货品备注
       Bidnumber, --中标流水号
       Supplyerid, --采购员
       Supplyername, --采购员
       Factoryid, --生产厂商id
       Factoryname, --生产厂商
       Goodsattribution, --商品归属地
       Businessman, --商务联系人
       Businessphone, --商务联系方式
       Clinicalman, --紧急联系人2
       Clinicalphone, --紧急联系方式2
       Supplyman, --紧急联系人
       Supplyphone, --紧急联系方式
       Payment_Method, --付款方式
       Paydate_Choice_Code, --付款起算日
       Terms) --账期
      SELECT Peg.Entryid,
             Peg.Goodsno, --货品编码
             Peg.Goodsid, --货品ID
             Peg.Goodsname, --通用名
             Peg.Currencyname, --商品名
             Peg.Goodstype, --规格
             Peg.Goodsunit, --最小单位
             Peg.Large_Tranfer_Rate, --件比
             Peg.Supplytaxrate, --税率
             Pc1.Specify_Price Price_Tax, -- 含税进价
             Pc2.Specify_Price Price_Hosp, --医院限制价格
             Peg.Goodsmemo, --货品备注
             Peg.Bidnumber, --中标流水号
             Peg.Supplyerid, --采购员id
             Peg.Supplyername, --采购员
             Peg.Factoryid, --生产厂商id
             Peg.Factoryname, --生产厂商
             Peg.Goodsattribution, --商品归属地
             Peg.Businessman, --商务联系人
             Peg.Businessphone, --商务联系方式
             Peg.Clinicalman, --紧急联系人2
             Peg.Clinicalphone, --紧急联系方式2
             Peg.Supplyman, --紧急联系人
             Peg.Supplyphone, --紧急联系方式
             (SELECT a.Settletype
                FROM Pub_Settletype_Ddl a
               WHERE a.Settletypeid <> 8
                 AND a.Settletypeid = Spc.Payment_Method) Payment_Method,
             (SELECT b.Ddlname
                FROM Sys_Ddl_Dtl_v b
               WHERE b.Sysid = 750
                 AND b.Ddlid = Spc.Paydate_Choice_Code) Paydate_Choice_Code,
             Spc.Terms
        FROM Pub_Entry_Goods_v        Peg,
             Bms_Ebs_Sa_Price_Catalog Pc1,
             Bms_Ebs_Sa_Price_Catalog Pc2,
             Bms_Ebs_Su_Price_Catalog Spc
       WHERE Peg.Entryid = Pc1.Entryid(+)
         AND Peg.Goodsid = Pc1.Goodsid(+)
         AND Pc1.Priceid(+) = 161
         AND Pc1.Active_Flag(+) = 1
         AND Pc1.Customid(+) IS NULL
         AND Pc1.Agentid(+) IS NULL
         AND Peg.Entryid = Pc2.Entryid(+)
         AND Peg.Goodsid = Pc2.Goodsid(+)
         AND Pc2.Priceid(+) = 169
         AND Pc2.Active_Flag(+) = 1
         AND Pc2.Customid(+) IS NULL
         AND Pc2.Agentid(+) IS NULL
         AND Peg.Entryid = Spc.Entryid(+)
         AND Peg.Goodsid = Spc.Goodsid(+)
         AND Spc.Only_Item_Flag(+) = 'Y'
         AND Spc.Usestatus(+) = 1
         AND (EXISTS (SELECT 1
                        FROM Bms_Sa_Doc Bsd, Bms_Sa_Dtl Sd
                       WHERE Sd.Goodsid = Peg.Goodsid
                         AND Bsd.Salesid = Sd.Salesid
                         AND Bsd.Entryid = Peg.Entryid
                         AND Bsd.Credate > Add_Months(SYSDATE, -3)
                         AND Bsd.Usestatus = 1) OR EXISTS
              (SELECT 1
                 FROM Bms_St_Qty_Lst Ql, Bms_St_Def St
                WHERE Ql.Goodsid = Peg.Goodsid
                  AND Ql.Storageid = St.Storageid
                  AND St.Entryid = Peg.Entryid
                  AND St.Storagename LIKE '河南公司合格库%'))
         AND Peg.Entryid = Nvl(p_Entryid, Peg.Entryid)
         AND Peg.Goodsid = Nvl(p_Goodsid, Peg.Goodsid)
         AND Peg.Suuesstatus = 1
         AND Peg.Gspusestatus = 1;
    FOR Rec_Goods IN Goods_Cur LOOP
      --销售订单条目数
      SELECT COUNT(DISTINCT Bs.Salesid)
        INTO v_Sales_Order
        FROM Bms_Sa_Doc Bs, Bms_Sa_Dtl Bb
       WHERE Bs.Salesid = Bb.Salesid
            --AND Bb.Goodsid = Rec_Goods.Goodsid
         AND Bb.Goodsid IN (SELECT s.Old_Goodsid
                              FROM Po_Plan_Goods_Conversion_Tl s
                             WHERE s.New_Goodsid = Rec_Goods.Goodsid
                               AND s.Entryid = Rec_Goods.Entryid
                            UNION ALL
                            SELECT s.New_Goodsid
                              FROM Po_Plan_Goods_Conversion_Tl s
                             WHERE s.New_Goodsid = Rec_Goods.Goodsid
                               AND s.Entryid = Rec_Goods.Entryid
                            UNION ALL
                            SELECT Rec_Goods.Goodsid
                              FROM Dual)
         AND Bs.Entryid = Rec_Goods.Entryid
         AND Bs.Credate >= Add_Months(Trunc(SYSDATE, 'mm'), -3)
         AND Bs.Credate < Trunc(SYSDATE, 'mm')
         AND Bs.Usestatus = 1;
      --销量1
      SELECT COUNT(1)
        INTO v_Count
        FROM Bms_Sa_Doc Bs, Bms_Sa_Dtl Bb
       WHERE Bs.Salesid = Bb.Salesid
            --AND Bb.Goodsid = Rec_Goods.Goodsid
         AND Bb.Goodsid IN (SELECT s.Old_Goodsid
                              FROM Po_Plan_Goods_Conversion_Tl s
                             WHERE s.New_Goodsid = Rec_Goods.Goodsid
                               AND s.Entryid = Rec_Goods.Entryid
                            UNION ALL
                            SELECT s.New_Goodsid
                              FROM Po_Plan_Goods_Conversion_Tl s
                             WHERE s.New_Goodsid = Rec_Goods.Goodsid
                               AND s.Entryid = Rec_Goods.Entryid
                            UNION ALL
                            SELECT Rec_Goods.Goodsid
                              FROM Dual)
         AND Bs.Entryid = Rec_Goods.Entryid
         AND Bs.Credate >= Add_Months(Trunc(SYSDATE, 'mm'), -3)
         AND Bs.Credate < Add_Months(Trunc(SYSDATE, 'mm'), -2)
         AND Bs.Usestatus = 1;
      IF v_Count > 0 THEN
        SELECT SUM(Bb.Goodsqty)
          INTO v_Sales_Count1
          FROM Bms_Sa_Doc Bs, Bms_Sa_Dtl Bb
         WHERE Bs.Salesid = Bb.Salesid
           AND Bb.Goodsid IN (SELECT s.Old_Goodsid
                                FROM Po_Plan_Goods_Conversion_Tl s
                               WHERE s.New_Goodsid = Rec_Goods.Goodsid
                                 AND s.Entryid = Rec_Goods.Entryid
                              UNION ALL
                              SELECT s.New_Goodsid
                                FROM Po_Plan_Goods_Conversion_Tl s
                               WHERE s.New_Goodsid = Rec_Goods.Goodsid
                                 AND s.Entryid = Rec_Goods.Entryid
                              UNION ALL
                              SELECT Rec_Goods.Goodsid
                                FROM Dual)
           AND Bs.Entryid = Rec_Goods.Entryid
           AND Bs.Credate >= Add_Months(Trunc(SYSDATE, 'mm'), -3)
           AND Bs.Credate < Add_Months(Trunc(SYSDATE, 'mm'), -2)
           AND Bs.Usestatus = 1;
      END IF;
      --销量2
      SELECT COUNT(1)
        INTO v_Count
        FROM Bms_Sa_Doc Bs, Bms_Sa_Dtl Bb
       WHERE Bs.Salesid = Bb.Salesid
         AND Bb.Goodsid IN (SELECT s.Old_Goodsid
                              FROM Po_Plan_Goods_Conversion_Tl s
                             WHERE s.New_Goodsid = Rec_Goods.Goodsid
                               AND s.Entryid = Rec_Goods.Entryid
                            UNION ALL
                            SELECT s.New_Goodsid
                              FROM Po_Plan_Goods_Conversion_Tl s
                             WHERE s.New_Goodsid = Rec_Goods.Goodsid
                               AND s.Entryid = Rec_Goods.Entryid
                            UNION ALL
                            SELECT Rec_Goods.Goodsid
                              FROM Dual)
         AND Bs.Entryid = Rec_Goods.Entryid
         AND Bs.Credate >= Add_Months(Trunc(SYSDATE, 'mm'), -2)
         AND Bs.Credate < Add_Months(Trunc(SYSDATE, 'mm'), -1)
         AND Bs.Usestatus = 1;
      IF v_Count > 0 THEN
        SELECT SUM(Bb.Goodsqty)
          INTO v_Sales_Count2
          FROM Bms_Sa_Doc Bs, Bms_Sa_Dtl Bb
         WHERE Bs.Salesid = Bb.Salesid
           AND Bb.Goodsid IN (SELECT s.Old_Goodsid
                                FROM Po_Plan_Goods_Conversion_Tl s
                               WHERE s.New_Goodsid = Rec_Goods.Goodsid
                                 AND s.Entryid = Rec_Goods.Entryid
                              UNION ALL
                              SELECT s.New_Goodsid
                                FROM Po_Plan_Goods_Conversion_Tl s
                               WHERE s.New_Goodsid = Rec_Goods.Goodsid
                                 AND s.Entryid = Rec_Goods.Entryid
                              UNION ALL
                              SELECT Rec_Goods.Goodsid
                                FROM Dual)
           AND Bs.Entryid = Rec_Goods.Entryid
           AND Bs.Credate >= Add_Months(Trunc(SYSDATE, 'mm'), -2)
           AND Bs.Credate < Add_Months(Trunc(SYSDATE, 'mm'), -1)
           AND Bs.Usestatus = 1;
      END IF;
      --销量3
      SELECT COUNT(1)
        INTO v_Count
        FROM Bms_Sa_Doc Bs, Bms_Sa_Dtl Bb
       WHERE Bs.Salesid = Bb.Salesid
         AND Bb.Goodsid IN (SELECT s.Old_Goodsid
                              FROM Po_Plan_Goods_Conversion_Tl s
                             WHERE s.New_Goodsid = Rec_Goods.Goodsid
                               AND s.Entryid = Rec_Goods.Entryid
                            UNION ALL
                            SELECT s.New_Goodsid
                              FROM Po_Plan_Goods_Conversion_Tl s
                             WHERE s.New_Goodsid = Rec_Goods.Goodsid
                               AND s.Entryid = Rec_Goods.Entryid
                            UNION ALL
                            SELECT Rec_Goods.Goodsid
                              FROM Dual)
         AND Bs.Entryid = Rec_Goods.Entryid
         AND Bs.Credate >= Add_Months(Trunc(SYSDATE, 'mm'), -1)
         AND Bs.Credate < Trunc(SYSDATE, 'mm')
         AND Bs.Usestatus = 1;
      IF v_Count > 0 THEN
        SELECT SUM(Bb.Goodsqty)
          INTO v_Sales_Count3
          FROM Bms_Sa_Doc Bs, Bms_Sa_Dtl Bb
         WHERE Bs.Salesid = Bb.Salesid
           AND Bb.Goodsid IN (SELECT s.Old_Goodsid
                                FROM Po_Plan_Goods_Conversion_Tl s
                               WHERE s.New_Goodsid = Rec_Goods.Goodsid
                                 AND s.Entryid = Rec_Goods.Entryid
                              UNION ALL
                              SELECT s.New_Goodsid
                                FROM Po_Plan_Goods_Conversion_Tl s
                               WHERE s.New_Goodsid = Rec_Goods.Goodsid
                                 AND s.Entryid = Rec_Goods.Entryid
                              UNION ALL
                              SELECT Rec_Goods.Goodsid
                                FROM Dual)
           AND Bs.Entryid = Rec_Goods.Entryid
           AND Bs.Credate >= Add_Months(Trunc(SYSDATE, 'mm'), -1)
           AND Bs.Credate < Trunc(SYSDATE, 'mm')
           AND Bs.Usestatus = 1;
      END IF;
      --去年同期销量
      /*      SELECT COUNT(1)
        INTO v_Count
        FROM Bms_Sa_Doc Bs, Bms_Sa_Dtl Bb
       WHERE Bs.Salesid = Bb.Salesid
         AND Bb.Goodsid IN (SELECT s.Old_Goodsid
                              FROM Po_Plan_Goods_Conversion_Tl s
                             WHERE s.New_Goodsid = Rec_Goods.Goodsid
                               AND s.Entryid = Rec_Goods.Entryid
                            UNION ALL
                            SELECT s.New_Goodsid
                              FROM Po_Plan_Goods_Conversion_Tl s
                             WHERE s.New_Goodsid = Rec_Goods.Goodsid
                               AND s.Entryid = Rec_Goods.Entryid
                            UNION ALL
                            SELECT Rec_Goods.Goodsid
                              FROM Dual)
         AND Bs.Entryid = Rec_Goods.Entryid
         AND Bs.Credate >= Add_Months(Trunc(SYSDATE, 'mm'), -12)
         AND Bs.Credate < Add_Months(Trunc(SYSDATE, 'mm'), -11)
         AND Bs.Usestatus = 1;
      IF v_Count > 0 THEN
        SELECT SUM(Bb.Goodsqty)
          INTO v_Last_Sales_Count
          FROM Bms_Sa_Doc Bs, Bms_Sa_Dtl Bb
         WHERE Bs.Salesid = Bb.Salesid
           AND Bb.Goodsid IN (SELECT s.Old_Goodsid
                                FROM Po_Plan_Goods_Conversion_Tl s
                               WHERE s.New_Goodsid = Rec_Goods.Goodsid
                                 AND s.Entryid = Rec_Goods.Entryid
                              UNION ALL
                              SELECT s.New_Goodsid
                                FROM Po_Plan_Goods_Conversion_Tl s
                               WHERE s.New_Goodsid = Rec_Goods.Goodsid
                                 AND s.Entryid = Rec_Goods.Entryid
                              UNION ALL
                              SELECT Rec_Goods.Goodsid
                                FROM Dual)
           AND Bs.Entryid = Rec_Goods.Entryid
           AND Bs.Credate >= Add_Months(Trunc(SYSDATE, 'mm'), -12)
           AND Bs.Credate < Add_Months(Trunc(SYSDATE, 'mm'), -11)
           AND Bs.Usestatus = 1;
      END IF;*/
    
      /*      --去年同期采购量
      SELECT COUNT(1)
        INTO v_Count
        FROM Bms_Su_Con_Doc Scd, Bms_Su_Con_Dtl Cd
       WHERE Scd.Suconid = Cd.Suconid
         AND Scd.Status = 2
         AND Scd.Credate >= Add_Months(Trunc(SYSDATE, 'mm'), -12)
         AND Scd.Credate < Add_Months(Trunc(SYSDATE, 'mm'), -11)
         AND Cd.Goodsid IN (SELECT s.Old_Goodsid
                              FROM Po_Plan_Goods_Conversion_Tl s
                             WHERE s.New_Goodsid = Rec_Goods.Goodsid
                               AND s.Entryid = Rec_Goods.Entryid
                            UNION ALL
                            SELECT s.New_Goodsid
                              FROM Po_Plan_Goods_Conversion_Tl s
                             WHERE s.New_Goodsid = Rec_Goods.Goodsid
                               AND s.Entryid = Rec_Goods.Entryid
                            UNION ALL
                            SELECT Rec_Goods.Goodsid
                              FROM Dual)
         AND Scd.Entryid = Rec_Goods.Entryid;*/
      --采购进货数量
      /*      IF v_Count > 0 THEN
        SELECT SUM(Cd.Goodsqty)
          INTO v_Po_In
          FROM Bms_Su_Con_Doc Scd, Bms_Su_Con_Dtl Cd
         WHERE Scd.Suconid = Cd.Suconid
           AND Scd.Status = 2
           AND Scd.Credate >= Add_Months(Trunc(SYSDATE, 'mm'), -12)
           AND Scd.Credate < Add_Months(Trunc(SYSDATE, 'mm'), -11)
           AND Cd.Goodsid IN (SELECT s.Old_Goodsid
                                FROM Po_Plan_Goods_Conversion_Tl s
                               WHERE s.New_Goodsid = Rec_Goods.Goodsid
                                 AND s.Entryid = Rec_Goods.Entryid
                              UNION ALL
                              SELECT s.New_Goodsid
                                FROM Po_Plan_Goods_Conversion_Tl s
                               WHERE s.New_Goodsid = Rec_Goods.Goodsid
                                 AND s.Entryid = Rec_Goods.Entryid
                              UNION ALL
                              SELECT Rec_Goods.Goodsid
                                FROM Dual)
           AND Scd.Entryid = Rec_Goods.Entryid;
      END IF;
      SELECT COUNT(1)
        INTO v_Count
        FROM Bms_Su_Doc Cu, Bms_Su_Dtl Lu
       WHERE Cu.Sudocid = Lu.Sudocid
         AND Cu.Sutypeid = 3
         AND Cu.Entryid = Rec_Goods.Entryid
         AND Lu.Goodsid IN (SELECT s.Old_Goodsid
                              FROM Po_Plan_Goods_Conversion_Tl s
                             WHERE s.New_Goodsid = Rec_Goods.Goodsid
                               AND s.Entryid = Rec_Goods.Entryid
                            UNION ALL
                            SELECT s.New_Goodsid
                              FROM Po_Plan_Goods_Conversion_Tl s
                             WHERE s.New_Goodsid = Rec_Goods.Goodsid
                               AND s.Entryid = Rec_Goods.Entryid
                            UNION ALL
                            SELECT Rec_Goods.Goodsid
                              FROM Dual)
         AND Cu.Usestatus = 1
         AND Cu.Credate >= Add_Months(Trunc(SYSDATE, 'mm'), -12)
         AND Cu.Credate < Add_Months(Trunc(SYSDATE, 'mm'), -11);
      --采购退货数量
      IF v_Count > 0 THEN
        SELECT SUM(Lu.Goodsqty)
          INTO v_Po_Out
          FROM Bms_Su_Doc Cu, Bms_Su_Dtl Lu
         WHERE Cu.Sudocid = Lu.Sudocid
           AND Cu.Sutypeid = 3
           AND Cu.Entryid = Rec_Goods.Entryid
           AND Lu.Goodsid IN (SELECT s.Old_Goodsid
                                FROM Po_Plan_Goods_Conversion_Tl s
                               WHERE s.New_Goodsid = Rec_Goods.Goodsid
                                 AND s.Entryid = Rec_Goods.Entryid
                              UNION ALL
                              SELECT s.New_Goodsid
                                FROM Po_Plan_Goods_Conversion_Tl s
                               WHERE s.New_Goodsid = Rec_Goods.Goodsid
                                 AND s.Entryid = Rec_Goods.Entryid
                              UNION ALL
                              SELECT Rec_Goods.Goodsid
                                FROM Dual)
           AND Cu.Usestatus = 1
           AND Cu.Credate >= Add_Months(Trunc(SYSDATE, 'mm'), -12)
           AND Cu.Credate < Add_Months(Trunc(SYSDATE, 'mm'), -11);
      END IF;
      v_Last_Po_Count := Nvl(v_Po_In, 0) - Nvl(v_Po_Out, 0);*/
      --本月已销量
      SELECT COUNT(1)
        INTO v_Count
        FROM Bms_Sa_Doc Bs, Bms_Sa_Dtl Bb
       WHERE Bs.Salesid = Bb.Salesid
         AND Bs.Entryid = Rec_Goods.Entryid
         AND Bb.Goodsid IN (SELECT s.Old_Goodsid
                              FROM Po_Plan_Goods_Conversion_Tl s
                             WHERE s.New_Goodsid = Rec_Goods.Goodsid
                               AND s.Entryid = Rec_Goods.Entryid
                            UNION ALL
                            SELECT s.New_Goodsid
                              FROM Po_Plan_Goods_Conversion_Tl s
                             WHERE s.New_Goodsid = Rec_Goods.Goodsid
                               AND s.Entryid = Rec_Goods.Entryid
                            UNION ALL
                            SELECT Rec_Goods.Goodsid
                              FROM Dual)
         AND Bs.Credate >= Trunc(SYSDATE, 'mm')
         AND Bs.Usestatus = 1;
      IF v_Count > 0 THEN
        SELECT SUM(Bb.Goodsqty)
          INTO v_Current_Sales_Count
          FROM Bms_Sa_Doc Bs, Bms_Sa_Dtl Bb
         WHERE Bs.Salesid = Bb.Salesid
           AND Bs.Entryid = Rec_Goods.Entryid
           AND Bb.Goodsid IN (SELECT s.Old_Goodsid
                                FROM Po_Plan_Goods_Conversion_Tl s
                               WHERE s.New_Goodsid = Rec_Goods.Goodsid
                                 AND s.Entryid = Rec_Goods.Entryid
                              UNION ALL
                              SELECT s.New_Goodsid
                                FROM Po_Plan_Goods_Conversion_Tl s
                               WHERE s.New_Goodsid = Rec_Goods.Goodsid
                                 AND s.Entryid = Rec_Goods.Entryid
                              UNION ALL
                              SELECT Rec_Goods.Goodsid
                                FROM Dual)
           AND Bs.Credate >= Trunc(SYSDATE, 'mm')
           AND Bs.Usestatus = 1;
      END IF;
      -- 月均销量
      SELECT COUNT(1)
        INTO v_Count
        FROM Bms_Sa_Doc Bs, Bms_Sa_Dtl Bb
       WHERE Bs.Salesid = Bb.Salesid
         AND Bb.Goodsid IN (SELECT s.Old_Goodsid
                              FROM Po_Plan_Goods_Conversion_Tl s
                             WHERE s.New_Goodsid = Rec_Goods.Goodsid
                               AND s.Entryid = Rec_Goods.Entryid
                            UNION ALL
                            SELECT s.New_Goodsid
                              FROM Po_Plan_Goods_Conversion_Tl s
                             WHERE s.New_Goodsid = Rec_Goods.Goodsid
                               AND s.Entryid = Rec_Goods.Entryid
                            UNION ALL
                            SELECT Rec_Goods.Goodsid
                              FROM Dual)
         AND Bs.Entryid = Rec_Goods.Entryid
         AND Bs.Credate >= Add_Months(Trunc(SYSDATE, 'mm'), -3)
         AND Bs.Credate < Trunc(SYSDATE, 'mm')
         AND Bs.Usestatus = 1;
      IF v_Count > 0 THEN
        SELECT Round(SUM(Bb.Goodsqty) / 3, 0)
          INTO v_Avg_Sales_Count
          FROM Bms_Sa_Doc Bs, Bms_Sa_Dtl Bb
         WHERE Bs.Salesid = Bb.Salesid
           AND Bb.Goodsid IN (SELECT s.Old_Goodsid
                                FROM Po_Plan_Goods_Conversion_Tl s
                               WHERE s.New_Goodsid = Rec_Goods.Goodsid
                                 AND s.Entryid = Rec_Goods.Entryid
                              UNION ALL
                              SELECT s.New_Goodsid
                                FROM Po_Plan_Goods_Conversion_Tl s
                               WHERE s.New_Goodsid = Rec_Goods.Goodsid
                                 AND s.Entryid = Rec_Goods.Entryid
                              UNION ALL
                              SELECT Rec_Goods.Goodsid
                                FROM Dual)
           AND Bs.Entryid = Rec_Goods.Entryid
           AND Bs.Credate >= Add_Months(Trunc(SYSDATE, 'mm'), -3)
           AND Bs.Credate < Trunc(SYSDATE, 'mm')
           AND Bs.Usestatus = 1;
      END IF;
      /*      --月均采购量
      SELECT COUNT(1)
        INTO v_Count
        FROM Bms_Su_Con_Doc Scd, Bms_Su_Con_Dtl Cd
       WHERE Scd.Suconid = Cd.Suconid
         AND Scd.Status = 2
         AND Scd.Credate >= Add_Months(Trunc(SYSDATE, 'mm'), -3)
         AND Scd.Credate < Trunc(SYSDATE, 'mm')
         AND Cd.Goodsid IN (SELECT s.Old_Goodsid
                              FROM Po_Plan_Goods_Conversion_Tl s
                             WHERE s.New_Goodsid = Rec_Goods.Goodsid
                               AND s.Entryid = Rec_Goods.Entryid
                            UNION ALL
                            SELECT s.New_Goodsid
                              FROM Po_Plan_Goods_Conversion_Tl s
                             WHERE s.New_Goodsid = Rec_Goods.Goodsid
                               AND s.Entryid = Rec_Goods.Entryid
                            UNION ALL
                            SELECT Rec_Goods.Goodsid
                              FROM Dual)
         AND Scd.Entryid = Rec_Goods.Entryid;
      --采购进货数量
      IF v_Count > 0 THEN
        SELECT Round(SUM(Cd.Goodsqty) / 3, 2)
          INTO v_Po_In
          FROM Bms_Su_Con_Doc Scd, Bms_Su_Con_Dtl Cd
         WHERE Scd.Suconid = Cd.Suconid
           AND Scd.Status = 2
           AND Scd.Credate >= Add_Months(Trunc(SYSDATE, 'mm'), -3)
           AND Scd.Credate < Trunc(SYSDATE, 'mm')
           AND Cd.Goodsid IN (SELECT s.Old_Goodsid
                                FROM Po_Plan_Goods_Conversion_Tl s
                               WHERE s.New_Goodsid = Rec_Goods.Goodsid
                                 AND s.Entryid = Rec_Goods.Entryid
                              UNION ALL
                              SELECT s.New_Goodsid
                                FROM Po_Plan_Goods_Conversion_Tl s
                               WHERE s.New_Goodsid = Rec_Goods.Goodsid
                                 AND s.Entryid = Rec_Goods.Entryid
                              UNION ALL
                              SELECT Rec_Goods.Goodsid
                                FROM Dual)
           AND Scd.Entryid = Rec_Goods.Entryid;
      END IF;
      SELECT COUNT(1)
        INTO v_Count
        FROM Bms_Su_Doc Cu, Bms_Su_Dtl Lu
       WHERE Cu.Sudocid = Lu.Sudocid
         AND Cu.Sutypeid = 3
         AND Cu.Entryid = Rec_Goods.Entryid
         AND Lu.Goodsid IN (SELECT s.Old_Goodsid
                              FROM Po_Plan_Goods_Conversion_Tl s
                             WHERE s.New_Goodsid = Rec_Goods.Goodsid
                               AND s.Entryid = Rec_Goods.Entryid
                            UNION ALL
                            SELECT s.New_Goodsid
                              FROM Po_Plan_Goods_Conversion_Tl s
                             WHERE s.New_Goodsid = Rec_Goods.Goodsid
                               AND s.Entryid = Rec_Goods.Entryid
                            UNION ALL
                            SELECT Rec_Goods.Goodsid
                              FROM Dual)
         AND Cu.Usestatus = 1
         AND Cu.Credate >= Add_Months(Trunc(SYSDATE, 'mm'), -3)
         AND Cu.Credate < Trunc(SYSDATE, 'mm');
      --采购退货数量
      IF v_Count > 0 THEN
        SELECT Round(SUM(Lu.Goodsqty) / 3, 2)
          INTO v_Po_Out
          FROM Bms_Su_Doc Cu, Bms_Su_Dtl Lu
         WHERE Cu.Sudocid = Lu.Sudocid
           AND Cu.Sutypeid = 3
           AND Cu.Entryid = Rec_Goods.Entryid
           AND Lu.Goodsid IN (SELECT s.Old_Goodsid
                                FROM Po_Plan_Goods_Conversion_Tl s
                               WHERE s.New_Goodsid = Rec_Goods.Goodsid
                                 AND s.Entryid = Rec_Goods.Entryid
                              UNION ALL
                              SELECT s.New_Goodsid
                                FROM Po_Plan_Goods_Conversion_Tl s
                               WHERE s.New_Goodsid = Rec_Goods.Goodsid
                                 AND s.Entryid = Rec_Goods.Entryid
                              UNION ALL
                              SELECT Rec_Goods.Goodsid
                                FROM Dual)
           AND Cu.Usestatus = 1
           AND Cu.Credate >= Add_Months(Trunc(SYSDATE, 'mm'), -3)
           AND Cu.Credate < Trunc(SYSDATE, 'mm');
      END IF;
      v_Avg_Po_Count := Nvl(v_Po_In, 0) - Nvl(v_Po_Out, 0);*/
      --当前库存数量
      SELECT COUNT(1)
        INTO v_Count
        FROM Bms_St_Qty_Lst Ql, Bms_St_Def St
       WHERE Ql.Goodsid IN (SELECT s.Old_Goodsid
                              FROM Po_Plan_Goods_Conversion_Tl s
                             WHERE s.New_Goodsid = Rec_Goods.Goodsid
                               AND s.Entryid = Rec_Goods.Entryid
                            UNION ALL
                            SELECT s.New_Goodsid
                              FROM Po_Plan_Goods_Conversion_Tl s
                             WHERE s.New_Goodsid = Rec_Goods.Goodsid
                               AND s.Entryid = Rec_Goods.Entryid
                            UNION ALL
                            SELECT Rec_Goods.Goodsid
                              FROM Dual)
         AND Ql.Storageid = St.Storageid
         AND St.Entryid = Rec_Goods.Entryid
         AND St.Storagename LIKE '河南公司合格库%';
      IF v_Count > 0 THEN
        SELECT SUM(Ql.Goodsqty)
          INTO v_Goodsqty
          FROM Bms_St_Qty_Lst Ql, Bms_St_Def St
         WHERE Ql.Goodsid IN (SELECT s.Old_Goodsid
                                FROM Po_Plan_Goods_Conversion_Tl s
                               WHERE s.New_Goodsid = Rec_Goods.Goodsid
                                 AND s.Entryid = Rec_Goods.Entryid
                              UNION ALL
                              SELECT s.New_Goodsid
                                FROM Po_Plan_Goods_Conversion_Tl s
                               WHERE s.New_Goodsid = Rec_Goods.Goodsid
                                 AND s.Entryid = Rec_Goods.Entryid
                              UNION ALL
                              SELECT Rec_Goods.Goodsid
                                FROM Dual)
           AND Ql.Storageid = St.Storageid
           AND St.Entryid = Rec_Goods.Entryid
           AND St.Storagename LIKE '河南公司合格库%';
      END IF;
      --可销库存
      SELECT COUNT(1)
        INTO v_Count
        FROM Zx_Bms_St_Goodsqty_Use_v a
       WHERE a.Goodsid = Rec_Goods.Goodsid
         AND a.Entryid = Rec_Goods.Entryid;
      IF v_Count > 0 THEN
        SELECT SUM(a.Goodsqty - Nvl(a.Tmpqty, 0))
          INTO v_Goodsqty_Use
          FROM Zx_Bms_St_Goodsqty_Use_v a
         WHERE a.Goodsid = Rec_Goods.Goodsid
           AND a.Entryid = Rec_Goods.Entryid;
      END IF;
      --近半年发生业务的供应商
      SELECT COUNT(1)
        INTO v_Count
        FROM Bms_Su_Con_Doc Scd, Bms_Su_Con_Dtl Cd
       WHERE Scd.Suconid = Cd.Suconid
         AND Scd.Status = 2
         AND Scd.Credate >= Add_Months(Trunc(SYSDATE, 'mm'), -6)
         AND Cd.Goodsid IN (SELECT s.Old_Goodsid
                              FROM Po_Plan_Goods_Conversion_Tl s
                             WHERE s.New_Goodsid = Rec_Goods.Goodsid
                               AND s.Entryid = Rec_Goods.Entryid
                            UNION ALL
                            SELECT s.New_Goodsid
                              FROM Po_Plan_Goods_Conversion_Tl s
                             WHERE s.New_Goodsid = Rec_Goods.Goodsid
                               AND s.Entryid = Rec_Goods.Entryid
                            UNION ALL
                            SELECT Rec_Goods.Goodsid
                              FROM Dual)
         AND Scd.Entryid = Rec_Goods.Entryid;
    
      IF v_Count > 0 THEN
        SELECT Listagg(s.Supplyid, ',') Within GROUP(ORDER BY s.Supplyid),
               Listagg(s.Supplyname, ',') Within GROUP(ORDER BY s.Supplyid)
          INTO v_Supplyid, v_Supplyname
          FROM (SELECT DISTINCT Scd.Supplyid, Scd.Supplyname
                  FROM Bms_Su_Con_Doc Scd, Bms_Su_Con_Dtl Cd
                 WHERE Scd.Suconid = Cd.Suconid
                   AND Scd.Status = 2
                   AND Scd.Credate >= Add_Months(Trunc(SYSDATE, 'mm'), -6)
                   AND Cd.Goodsid IN
                       (SELECT s.Old_Goodsid
                          FROM Po_Plan_Goods_Conversion_Tl s
                         WHERE s.New_Goodsid = Rec_Goods.Goodsid
                           AND s.Entryid = Rec_Goods.Entryid
                        UNION ALL
                        SELECT s.New_Goodsid
                          FROM Po_Plan_Goods_Conversion_Tl s
                         WHERE s.New_Goodsid = Rec_Goods.Goodsid
                           AND s.Entryid = Rec_Goods.Entryid
                        UNION ALL
                        SELECT Rec_Goods.Goodsid
                          FROM Dual)
                   AND Scd.Entryid = Rec_Goods.Entryid) s;
      END IF;
      --长度过长时，置为空
      IF Lengthb(v_Supplyname) > 4000 THEN
        v_Supplyname := NULL;
        v_Supplyid   := NULL;
      END IF;
    
      --当日计划
      /*      SELECT COUNT(1)
        INTO v_Count
        FROM Bms_Su_Con_Doc Scd, Bms_Su_Con_Dtl Cd
       WHERE Scd.Suconid = Cd.Suconid
         AND Scd.Credate >= Trunc(SYSDATE, 'dd')
         AND Cd.Goodsid = Rec_Goods.Goodsid
         AND Scd.Entryid = Rec_Goods.Entryid;
      IF v_Count > 0 THEN
        SELECT SUM(Cd.Goodsqty)
          INTO v_Plan_Qty
          FROM Bms_Su_Con_Doc Scd, Bms_Su_Con_Dtl Cd
         WHERE Scd.Suconid = Cd.Suconid
           AND Scd.Credate >= Trunc(SYSDATE, 'dd')
           AND Cd.Goodsid = Rec_Goods.Goodsid
           AND Scd.Entryid = Rec_Goods.Entryid;
      END IF;*/
      --15天在途数量
      SELECT COUNT(1)
        INTO v_Count
        FROM Bms_Su_Con_Doc Scd, Bms_Su_Con_Dtl Cd
       WHERE Scd.Suconid = Cd.Suconid
         AND Scd.Credate >= SYSDATE - 15
         AND Cd.Goodsid = Rec_Goods.Goodsid
         AND Cd.Usestatus IN (1, 2, 6)
         AND Scd.Entryid = Rec_Goods.Entryid;
      IF v_Count > 0 THEN
        SELECT SUM(Cd.Goodsqty - Nvl(Cd.Inqty, 0))
          INTO v_Online_Qty
          FROM Bms_Su_Con_Doc Scd, Bms_Su_Con_Dtl Cd
         WHERE Scd.Suconid = Cd.Suconid
           AND Scd.Credate >= SYSDATE - 15
           AND Cd.Goodsid = Rec_Goods.Goodsid
           AND Cd.Usestatus IN (1, 2, 6)
           AND Scd.Entryid = Rec_Goods.Entryid;
      END IF;
    
      UPDATE Po_Plan_Source_Data_Tl a
         SET a.Sales_Order  = Nvl(v_Sales_Order, 0), --近三月销量
             a.Sales_Count1 = Nvl(v_Sales_Count1, 0), --近三月销量1
             a.Sales_Count2 = Nvl(v_Sales_Count2, 0), --近三月销量2
             a.Sales_Count3 = Nvl(v_Sales_Count3, 0), --近三月销量3
             --a.Last_Sales_Count    = v_Last_Sales_Count, --去年同期销量
             --a.Last_Po_Count       = v_Last_Po_Count, --去年同期采购量
             a.Current_Sales_Count = Nvl(v_Current_Sales_Count, 0), --本月已销量
             a.Avg_Sales_Count     = Nvl(v_Avg_Sales_Count, 0), --月平均销量
             a.Goodsqty            = Nvl(v_Goodsqty, 0), --当前库存
             a.Goodsqty_Use        = Nvl(v_Goodsqty_Use, 0), --可销库存
             --a.Plan_Qty            = v_Plan_Qty, --当日计划
             a.Online_Qty = Nvl(v_Online_Qty, 0), --15天在途数量
             --a.Avg_Po_Count = v_Avg_Po_Count, --月均采购量
             a.Supplyid   = v_Supplyid, --供应商id
             a.Supplyname = v_Supplyname --供应商
       WHERE a.Entryid = Rec_Goods.Entryid
         AND a.Goodsid = Rec_Goods.Goodsid;
    
      v_Sales_Order  := 0; --近三月销量
      v_Sales_Count1 := 0; --近三月销量1
      v_Sales_Count2 := 0; --近三月销量2
      v_Sales_Count3 := 0; --近三月销量3
      --v_Last_Sales_Count    := NULL; --去年同期销量
      --v_Last_Po_Count       := NULL; --去年同期采购量
      v_Current_Sales_Count := NULL; --本月已销量
      v_Avg_Sales_Count     := NULL; --月平均销量
      v_Goodsqty            := NULL; --当前库存
      v_Goodsqty_Use        := NULL; --可销库存
      --v_Plan_Qty            := NULL; --当日计划
      v_Online_Qty := NULL;
      v_Po_In      := NULL;
      v_Po_Out     := NULL;
      v_Supplyid   := NULL;
      v_Supplyname := NULL;
    
    END LOOP;
    COMMIT;
  END;
  /*
  采购订单临时转正式
  */
  PROCEDURE Po_Tmp_To_Formal_Sp IS
    CURSOR Po_Doc_Tmp IS
      SELECT * FROM Bms_Su_Con_Doc_Tmp WHERE Status = 0;
    CURSOR Po_Dtl_Tmp(p_Suconid NUMBER) IS
      SELECT * FROM Bms_Su_Con_Dtl_Tmp s WHERE s.Suconid = p_Suconid;
    --主表字段
    v_Supplyname Bms_Su_Con_Doc.Supplyname%TYPE; --供应商名称
    v_Signman    Bms_Su_Con_Doc.Signman%TYPE;
    v_Total      Bms_Su_Con_Doc.Total%TYPE; --总金额
    v_Storerid   Bms_Su_Con_Doc.Storageid%TYPE; --仓库ID
    v_Storageid  Bms_Su_Con_Doc.Storageid%TYPE; --保管帐ID 
    v_Deptid     Bms_Su_Con_Doc.Deptid%TYPE; --业务部门id
    v_Addressid  Bms_Su_Con_Doc.Addressid%TYPE; --供应商地址ID
  
    v_Goodsdtlid          Bms_Su_Con_Dtl.Goodsdtlid%TYPE; --货品外包装id
    v_Goodsuseunit        Bms_Su_Con_Dtl.Goodsuseunit%TYPE; --使用单位
    v_Taxrate             Bms_Su_Con_Dtl.Taxrate%TYPE; --税率
    v_Unitprice           Bms_Su_Con_Dtl.Unitprice%TYPE; --单价
    v_Total_Line          Bms_Su_Con_Dtl.Total_Line%TYPE; --金额
    v_Lastprice           Bms_Su_Con_Dtl.Lastprice%TYPE; --上次价格
    v_Lowestprice         Bms_Su_Con_Dtl.Lowestprice%TYPE; --最低进价
    v_Supplylastprice     Bms_Su_Con_Dtl.Supplylastprice%TYPE; --此供应商最近进价
    v_Paylimit            Bms_Su_Con_Dtl.Paylimit%TYPE; --付款账期
    v_Settletypeid        Bms_Su_Con_Dtl.Settletypeid%TYPE; --付款方式
    v_Zx_Bigpacageqty     Bms_Su_Con_Dtl.Zx_Bigpacageqty%TYPE; --大包装数量
    v_Line_Id             Bms_Su_Con_Dtl.Line_Id%TYPE; --采购价目明细id
    v_Uplimitqty          Bms_Su_Con_Dtl.Uplimitqty%TYPE; --上限数量
    v_Stockqty            Bms_Su_Con_Dtl.Stockqty%TYPE; --库存数量
    v_Costprice           Bms_Su_Con_Dtl.Costprice%TYPE; --成本单价
    v_Cost                Bms_Su_Con_Dtl.Cost%TYPE; --成本金额
    v_Lastthreemonthsaqty Bms_Su_Con_Dtl.Lastthreemonthsaqty%TYPE; --近三月销量
    v_Avgdayqty           Bms_Su_Con_Dtl.Avgdayqty%TYPE; --日均销量
    v_Sanotioqty          Bms_Su_Con_Dtl.Sanotioqty%TYPE; --已销未出库数量
    v_Twogoodsattribute   Bms_Su_Con_Dtl.Twogoodsattribute%TYPE; --两票制属性
    v_Zxgoodstype         Bms_Su_Con_Dtl.Zxgoodstype%TYPE; --货品两票制属性
    v_Usepacksize         Bms_Su_Con_Dtl.Usepacksize%TYPE; --使用单位大小
    v_Cansaledays         Bms_Su_Con_Dtl.Cansaledays%TYPE; --可销天数
    v_Upqty               Bms_Su_Con_Dtl.Upqty%TYPE; --可采购数量
    v_Commoditytype       Pub_Entry_Goods.Commoditytype%TYPE; --商品类型
    v_Online_Qty          NUMBER(16, 6); --15天在途数量
  BEGIN
    FOR Po_Header_Cur IN Po_Doc_Tmp LOOP
      --供应商名称
      SELECT MAX(Ps.Supplyname)
        INTO v_Supplyname
        FROM Pub_Supplyer Ps
       WHERE Ps.Supplyid = Po_Header_Cur.Supplyid;
      --签约人
      SELECT MAX(Pe.Employeename)
        INTO v_Signman
        FROM Pub_Employee Pe
       WHERE Pe.Employeeid = Po_Header_Cur.Supplyerid;
      --订单金额
      --SELECT sum(dt.) FROM Bms_Su_Con_Dtl_Tmp dt where dt.suconid = Po_Header_Cur.Suconid;
      --获取仓库ID
      SELECT MIN(s.Storerid)
        INTO v_Storerid
        FROM Pub_Storer s
       WHERE s.Usestatus = 1
            --AND s.Storerid <> 112
         AND s.Entryid = Po_Header_Cur.Entryid;
      --保管帐ID 
      SELECT MIN(s.Storageid)
        INTO v_Storageid
        FROM Bms_St_Def s
       WHERE s.Entryid = Po_Header_Cur.Entryid
         AND s.Storagetype = 1
         AND s.Phystoreid = v_Storerid
         AND s.Storagename LIKE '%合格库%'
         AND s.Storagename NOT LIKE '%不%';
    
      --业务部门id
      SELECT Pe.Deptid
        INTO v_Deptid
        FROM Pub_Employee Pe
       WHERE Pe.Employeeid = Po_Header_Cur.Supplyerid;
      --供应商地址id
      SELECT Ad.Agentno
        INTO v_Addressid
        FROM Bms_Agent_Def Ad
       WHERE Ad.Agentid = Po_Header_Cur.Agentid;
    
      INSERT INTO Hrhnprod.Bms_Su_Con_Doc
        (Suconid,
         Supplyid,
         Supplyname,
         Contracttype,
         Importflag,
         Signdate,
         Signman,
         Validbegdate,
         Validenddate,
         Settletypeid,
         Prepay,
         Agentflag,
         Switchmode,
         Total,
         Dtl_Lines,
         Fmid,
         Exchange,
         Entryid,
         Sourcetype,
         Credate,
         Inputmanid,
         Agentid,
         Storerid,
         Expectgetdate,
         Storageid,
         Supplyerid,
         Deptid,
         Addressid,
         Status,
         Zx_Agentid,
         Zx_Exceptiontype)
      VALUES
        (Po_Header_Cur.Suconid,
         Po_Header_Cur.Supplyid,
         v_Supplyname,
         1, --订单类型默认1(计划订单)
         0, --进口标识 默认为0
         Po_Header_Cur.Credate, --签订日期
         v_Signman, --签约人
         Po_Header_Cur.Credate, --开始日期
         Po_Header_Cur.Credate, --结束日期
         5, --付款方式 默认5
         0, --prepay 默认0
         0, --代理方式 默认0(经销)
         2, --交接方式 默认2(送货)
         v_Total, --总金额
         Po_Header_Cur.Dtl_Lines, --细单条数
         0, --外币ID
         1, --汇率
         Po_Header_Cur.Entryid,
         7, --来源类型
         Po_Header_Cur.Credate, --创建日期
         Po_Header_Cur.Inputmanid,
         Po_Header_Cur.Agentid,
         v_Storerid,
         Po_Header_Cur.Credate + 7, --预计到货时间
         v_Storageid,
         Po_Header_Cur.Supplyerid,
         v_Deptid,
         v_Addressid, --供应商地址id
         1, --订单状态默认1(临时)
         Po_Header_Cur.Zx_Agentid,
         Po_Header_Cur.Zx_Exceptiontype);
    
      FOR Po_Line_Cur IN Po_Dtl_Tmp(Po_Header_Cur.Suconid) LOOP
        --货品外包装id
        SELECT MAX(b.Goodsdtlid)
          INTO v_Goodsdtlid
          FROM Pub_Goods_Detail b
         WHERE b.Goodsid = Po_Line_Cur.Goodsid
           AND b.Usestatus = 1;
        --使用单位,使用单位数量
        SELECT MAX(b.Goodsunit), MAX(b.Baseunitqty)
          INTO v_Goodsuseunit, v_Usepacksize
          FROM Pub_Goods_Unit b
         WHERE b.Goodsid = Po_Line_Cur.Goodsid
           AND b.Baseflag = 1;
        --税率
        /*        SELECT MAX(Pg.Supplytaxrate)
         INTO v_Taxrate
         FROM Pub_Goods Pg
        WHERE Pg.Goodsid = Po_Line_Cur.Goodsid
          AND Pg.Usestatus = 1;*/
        --价格、税率、付款账期
        SELECT MAX(a.Unit_Price),
               MAX(a.Tax_Code),
               MAX(a.Terms),
               MAX(a.Payment_Method),
               MAX(a.Line_Id)
          INTO v_Unitprice,
               v_Taxrate,
               v_Paylimit,
               v_Settletypeid,
               v_Line_Id
          FROM Bms_Ebs_Su_Price_Catalog a
         WHERE a.Usestatus = 1
           AND a.Entryid = Po_Header_Cur.Entryid
           AND a.Goodsid = Po_Line_Cur.Goodsid
           AND a.Buyer = Po_Header_Cur.Supplyerid
           AND a.Companyid = Po_Header_Cur.Supplyid
           AND a.Agentid = Po_Header_Cur.Agentid
           AND a.Only_Item_Flag = 'N'
           AND Trunc(SYSDATE) BETWEEN Trunc(a.Effective_Start_Date) AND
               Trunc(Nvl(a.Effective_End_Date, SYSDATE + 1));
        IF v_Unitprice IS NULL THEN
          SELECT MAX(a.Unit_Price),
                 MAX(a.Tax_Code),
                 MAX(a.Terms),
                 MAX(a.Payment_Method),
                 MAX(a.Line_Id)
            INTO v_Unitprice,
                 v_Taxrate,
                 v_Paylimit,
                 v_Settletypeid,
                 v_Line_Id
            FROM Bms_Ebs_Su_Price_Catalog a
           WHERE a.Usestatus = 1
             AND a.Entryid = Po_Header_Cur.Entryid
             AND a.Goodsid = Po_Line_Cur.Goodsid
             AND a.Only_Item_Flag = 'Y'
             AND a.Buyer = Po_Header_Cur.Supplyerid
             AND Trunc(SYSDATE) BETWEEN Trunc(a.Effective_Start_Date) AND
                 Trunc(Nvl(a.Effective_End_Date, SYSDATE + 1));
        END IF;
        v_Total_Line := Nvl(v_Unitprice, 0) * Po_Line_Cur.Goodsuseqty;
        v_Total      := Nvl(v_Total, 0) + v_Total_Line;
      
        /*        SELECT s.Conprice
         INTO v_Lastprice
         FROM (SELECT Cd.Conprice, Bsd.Credate
                 FROM Bms_Su_Doc Bsd, Bms_Su_Dtl Cd
                WHERE Bsd.Sudocid = Cd.Sudocid
                  AND Bsd.Entryid = Po_Header_Cur.Entryid
                  AND Cd.Goodsid = Po_Line_Cur.Goodsid
                  AND Bsd.Sutypeid = 1
                  AND Bsd.Usestatus = 1
                ORDER BY Bsd.Credate DESC) s
        WHERE Rownum = 1;*/
      
        --最近进价,最低进价
        SELECT MAX(b.Lastprice), MAX(b.Lowestprice)
          INTO v_Lastprice, v_Lowestprice
          FROM Bms_Goods_Suprice_Ref b
         WHERE Entryid = Po_Header_Cur.Entryid
           AND Goodsid = Po_Line_Cur.Goodsid;
        --此供应商最近进价
        SELECT MAX(b.Lastprice)
          INTO v_Supplylastprice
          FROM Bms_Goods_Suprice_Supply_Ref b
         WHERE Entryid = Po_Header_Cur.Entryid
           AND Supplyid = Po_Header_Cur.Supplyid
           AND Goodsid = Po_Line_Cur.Goodsid;
        --成本单价及金额
        v_Costprice := v_Unitprice / (1 + v_Taxrate);
        v_Cost      := v_Costprice * Po_Line_Cur.Goodsuseqty;
      
        --大包装数量
        SELECT MAX(Round(Po_Line_Cur.Goodsuseqty / Peg.Large_Tranfer_Rate,
                         6))
          INTO v_Zx_Bigpacageqty
          FROM Pub_Entry_Goods Peg
         WHERE Peg.Goodsid = Po_Line_Cur.Goodsid
           AND Peg.Entryid = Po_Header_Cur.Entryid;
      
        --上限数量
        SELECT MAX(s.Upqty)
          INTO v_Uplimitqty
          FROM Bms_Busi_Dtl s
         WHERE s.Entryid = Po_Header_Cur.Entryid
           AND s.Goodsid = Po_Line_Cur.Goodsid;
        --库存数量
        SELECT a.Stqty
          INTO v_Stockqty
          FROM Bms_Calc_Busi_Stqty_v a
         WHERE a.Entryid = Po_Header_Cur.Entryid
           AND a.Goodsid = Po_Line_Cur.Goodsid;
        --近三月销量
        SELECT SUM(Sd.Goodsqty)
          INTO v_Lastthreemonthsaqty
          FROM Bms_Sa_Doc Bsd, Bms_Sa_Dtl Sd
         WHERE Bsd.Salesid = Sd.Salesid
           AND Bsd.Credate > Add_Months(SYSDATE, -3)
           AND Bsd.Entryid = Po_Header_Cur.Entryid
           AND Sd.Goodsid = Po_Line_Cur.Goodsid;
        --日均销量
        v_Avgdayqty := v_Lastthreemonthsaqty / 90;
        --已销未出库数量
        SELECT SUM(Sd.Goodsqty)
          INTO v_Sanotioqty
          FROM Bms_Sa_Doc Bsd, Bms_Sa_Dtl Sd
         WHERE Bsd.Salesid = Sd.Salesid
           AND Bsd.Entryid = Po_Header_Cur.Entryid
           AND Sd.Goodsid = Po_Line_Cur.Goodsid
           AND Sd.Stioflag IS NULL;
        --货品两票制属性
        SELECT MAX(Peg.Twogoodsattribute)
          INTO v_Twogoodsattribute
          FROM Pub_Entry_Goods Peg
         WHERE Peg.Entryid = Po_Header_Cur.Entryid
           AND Peg.Goodsid = Po_Line_Cur.Goodsid;
        --货品两票制属性
        IF v_Twogoodsattribute = 0 THEN
          v_Zxgoodstype := 1;
        END IF;
        --可采购数量
        --可采购数量=上限数量-库存数量-15天内在途订单数量+已开单未出库数量
        BEGIN
          SELECT SUM(Cd.Goodsqty - Nvl(Cd.Inqty, 0))
            INTO v_Online_Qty
            FROM Bms_Su_Con_Doc Scd, Bms_Su_Con_Dtl Cd
           WHERE Scd.Suconid = Cd.Suconid
             AND Scd.Credate >= SYSDATE - 15
             AND Cd.Goodsid = Po_Line_Cur.Goodsid
             AND Cd.Usestatus IN (1, 2, 6)
             AND Scd.Entryid = Po_Header_Cur.Entryid;
        EXCEPTION
          WHEN OTHERS THEN
            v_Online_Qty := NULL;
        END;
      
        v_Upqty := Nvl(v_Uplimitqty, 0) - Nvl(v_Stockqty, 0) -
                   Nvl(v_Online_Qty, 0) + Nvl(v_Sanotioqty, 0);
      
        --可销天数
        /*
        可销天数    计算逻辑是：
        当货品在pub_entry_goods.commoditytype in(11,13)时，
        可销天数=7天内未入库采购订单数量/日均销量，
        否则，可销天数=（7天内未入库采购订单数量+当时库存）/日均销量
        */
      
        --商品类型
        SELECT MAX(Peg.Commoditytype)
          INTO v_Commoditytype
          FROM Pub_Entry_Goods Peg
         WHERE Peg.Entryid = Po_Header_Cur.Entryid
           AND Peg.Goodsid = Po_Line_Cur.Goodsid;
      
        IF v_Commoditytype IN (11, 13) THEN
          BEGIN
            SELECT SUM(Nvl(b.Goodsqty, 0) - Nvl(b.Accqty, 0)) / v_Avgdayqty
              INTO v_Cansaledays
              FROM Bms_Su_Con_Doc a, Bms_Su_Con_Dtl b
             WHERE a.Suconid = b.Suconid
               AND a.Entryid = Po_Header_Cur.Entryid
               AND b.Usestatus <> 5
               AND b.Goodsid = Po_Line_Cur.Goodsid
               AND a.Credate >= Trunc(SYSDATE) - 7
             GROUP BY b.Goodsid;
          EXCEPTION
            WHEN No_Data_Found THEN
              v_Cansaledays := NULL;
            WHEN OTHERS THEN
              v_Cansaledays := NULL;
          END;
        ELSE
          BEGIN
            SELECT (SUM(Nvl(b.Goodsqty, 0) - Nvl(b.Accqty, 0)) +
                   Nvl((SELECT SUM(Nvl(t.Goodsqty, 0))
                          FROM Bms_St_Qty_Lst t
                         WHERE b.Goodsid = t.Goodsid
                           AND t.Storageid = v_Storageid),
                        0)) / v_Avgdayqty
              INTO v_Cansaledays
              FROM Bms_Su_Con_Doc a, Bms_Su_Con_Dtl b
             WHERE a.Suconid = b.Suconid
               AND a.Entryid = Po_Header_Cur.Entryid
               AND b.Usestatus <> 5
               AND b.Goodsid = Po_Line_Cur.Goodsid
               AND a.Credate >= Trunc(SYSDATE) - 7
             GROUP BY b.Goodsid;
          EXCEPTION
            WHEN No_Data_Found THEN
              v_Cansaledays := NULL;
            WHEN OTHERS THEN
              v_Cansaledays := NULL;
          END;
        END IF;
      
        INSERT INTO Hrhnprod.Bms_Su_Con_Dtl
          (Sucondtlid,
           Suconid,
           Supplyerid,
           Deptid,
           Goodsid,
           Goodsdtlid,
           Goodsqty,
           Goodsuseunit,
           Goodsuseqty,
           Taxrate,
           Unitprice,
           Total_Line,
           Usestatus,
           Agreedocflag,
           Lastprice,
           Lowestprice,
           Supplylastprice,
           Paymethod,
           Paylimit,
           Usepacksize,
           Settletypeid,
           Zx_Bigpacageqty,
           Costprice,
           Cost,
           Upqty,
           Line_Id,
           Ckpaymethod,
           Ckpaylimit,
           Cksettletypeid,
           Uplimitqty,
           Avgdayqty,
           Stockqty,
           Sanotioqty,
           Lastthreemonthsaqty,
           Zxgoodstype,
           Twogoodsattribute,
           Cansaledays)
        VALUES
          (Po_Line_Cur.Sucondtlid,
           Po_Line_Cur.Suconid,
           Po_Header_Cur.Supplyerid, --采购员id
           v_Deptid, --业务部门id
           Po_Line_Cur.Goodsid,
           v_Goodsdtlid,
           Po_Line_Cur.Goodsuseqty,
           v_Goodsuseunit, --使用单位
           Po_Line_Cur.Goodsuseqty, --使用单位数量
           v_Taxrate,
           v_Unitprice,
           v_Total_Line,
           1, --状态
           0, --是否有进货协议
           v_Lastprice, --上次进价
           v_Lowestprice, --最低进价
           v_Supplylastprice, --此供应商最近进价
           1, --承付模式 默认1
           v_Paylimit, --付款账期
           v_Usepacksize, --使用单位大小
           v_Settletypeid, --付款方式
           v_Zx_Bigpacageqty, --大包装数量
           v_Costprice, --成本单价
           v_Cost, --成本金额
           v_Upqty, --可采购数量
           v_Line_Id, --采购价目明细id
           1, --参考承付模式
           v_Paylimit, --参考付款账期
           v_Settletypeid, --参考付款方式
           v_Uplimitqty, --上限数量
           v_Avgdayqty, --日均销量
           v_Stockqty, --库存数量
           v_Sanotioqty, --已销未出库数量
           v_Lastthreemonthsaqty,
           v_Zxgoodstype,
           v_Twogoodsattribute,
           v_Cansaledays);
      END LOOP;
      UPDATE Bms_Su_Con_Doc a
         SET a.Total = v_Total
       WHERE a.Suconid = Po_Header_Cur.Suconid;
      UPDATE Bms_Su_Con_Doc_Tmp
         SET Status = 1
       WHERE Suconid = Po_Header_Cur.Suconid;
      v_Total := 0;
    END LOOP;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      Dbms_Output.Put_Line(SQLCODE || '  ' || SQLERRM);
      ROLLBACK;
  END Po_Tmp_To_Formal_Sp;

  /***
  实时获取当日计划和15天在途数量
  ***/
  PROCEDURE Get_Goods_Info_Sp(p_Goods_List IN In_Goods_List,
                              x_Goods_Res  OUT Get_Goods_List) IS
  
    v_Count      NUMBER;
    v_Plan_Qty   NUMBER;
    v_Online_Qty NUMBER;
  BEGIN
  
    FOR i IN 1 .. p_Goods_List.Count LOOP
      --当日计划
      SELECT COUNT(1)
        INTO v_Count
        FROM Bms_Su_Con_Doc Scd, Bms_Su_Con_Dtl Cd
       WHERE Scd.Suconid = Cd.Suconid
         AND Scd.Credate >= Trunc(SYSDATE, 'dd')
         AND Cd.Goodsid = p_Goods_List(i).Goodsid
         AND Scd.Entryid = p_Goods_List(i).Entryid;
      IF v_Count > 0 THEN
        SELECT SUM(Cd.Goodsqty)
          INTO v_Plan_Qty
          FROM Bms_Su_Con_Doc Scd, Bms_Su_Con_Dtl Cd
         WHERE Scd.Suconid = Cd.Suconid
           AND Scd.Credate >= Trunc(SYSDATE, 'dd')
           AND Cd.Goodsid = p_Goods_List(i).Goodsid
           AND Scd.Entryid = p_Goods_List(i).Entryid;
      END IF;
    
      --15天在途数量
      SELECT COUNT(1)
        INTO v_Count
        FROM Bms_Su_Con_Doc Scd, Bms_Su_Con_Dtl Cd
       WHERE Scd.Suconid = Cd.Suconid
         AND Scd.Credate >= SYSDATE - 15
         AND Cd.Goodsid = p_Goods_List(i).Goodsid
         AND Cd.Usestatus IN (1, 2, 6)
         AND Scd.Entryid = p_Goods_List(i).Entryid;
      IF v_Count > 0 THEN
        SELECT SUM(Cd.Goodsqty - Nvl(Cd.Inqty, 0))
          INTO v_Online_Qty
          FROM Bms_Su_Con_Doc Scd, Bms_Su_Con_Dtl Cd
         WHERE Scd.Suconid = Cd.Suconid
           AND Scd.Credate >= SYSDATE - 15
           AND Cd.Goodsid = p_Goods_List(i).Goodsid
           AND Cd.Usestatus IN (1, 2, 6)
           AND Scd.Entryid = p_Goods_List(i).Entryid;
      END IF;
      x_Goods_Res(i).Entryid := p_Goods_List(i).Entryid;
      x_Goods_Res(i).Goodsid := p_Goods_List(i).Goodsid;
      x_Goods_Res(i).Plan_Qty := v_Plan_Qty;
      x_Goods_Res(i).Online_Qty := v_Online_Qty;
      v_Count := NULL;
      v_Plan_Qty := NULL;
      v_Online_Qty := NULL;
    END LOOP;
  END;

  PROCEDURE Po_Goods_Info_Sp(p_Goods_List IN Goods_Tbl_Type,
                             x_Goods_Res  OUT Goods_Tbl_List) IS
  
    My_Goods_List Goods_Tbl_List;
    k             NUMBER := 1;
  BEGIN
    IF p_Goods_List.Count >= 1 THEN
      FOR i IN 1 .. p_Goods_List.Count LOOP
        SELECT Peg.Entryid,
               Peg.Goodsid,
               Peg.Goodsname,
               Peg.Goodstype,
               Peg.Factoryname
          INTO My_Goods_List(k)
          FROM Pub_Entry_Goods_v Peg
         WHERE Peg.Entryid = p_Goods_List(i).Entryid
           AND Peg.Goodsid = p_Goods_List(i).Goodsid;
        k := k + 1;
      END LOOP;
    END IF;
    x_Goods_Res := My_Goods_List;
  END;

  /*供应商证照校验*/
  PROCEDURE Po_Plan_Check_License_Sp(Datajson IN CLOB, Appmess OUT CLOB) IS
    Get_Json     Json;
    Get_Jsonlist Json_List;
    v_Count      NUMBER;
    --out_son_list Supplyid_Entryid_out_son_list;
    v_Entryid    NUMBER;
    v_Supplyid   NUMBER;
    Get_Str      VARCHAR2(4000);
    v_Entryname  VARCHAR2(100);
    v_Supplyname VARCHAR2(100);
  BEGIN
  
    Get_Jsonlist := Json_List(Datajson);
    FOR i IN 1 .. 1 /*Get_Jsonlist.Count*/
     LOOP
      Get_Json   := Json(Get_Jsonlist.Get(i));
      v_Supplyid := Get_Jsonnumber(Get_Json, 'supplyid');
      v_Entryid  := Get_Jsonnumber(Get_Json, 'entryid');
      v_Count    := 1;
      SELECT Pe.Entryname
        INTO v_Entryname
        FROM Pub_Entry Pe
       WHERE Pe.Entryid = v_Entryid;
      SELECT Ps.Supplyname
        INTO v_Supplyname
        FROM Pub_Supplyer Ps
       WHERE Ps.Supplyid = v_Supplyid;
      FOR p_Cur IN (SELECT c.Licensetypeid, d.Licensename
                      FROM Pub_Entry_Supplyer a,
                           Gsp_Category_Doc   b,
                           Gsp_Category_Dtl   c,
                           Gsp_License_Type   d
                     WHERE a.Gspcategoryid = b.Categoryid
                       AND b.Categoryid = c.Categoryid
                       AND c.Licensetypeid = d.Licensetypeid
                       AND Nvl(d.Rangeflag, 0) = 0
                       AND a.Supplyid = v_Supplyid
                       AND a.Entryid = v_Entryid) LOOP
      
        FOR p_Cur1 IN /*(SELECT b.Usestatus, b.Validenddate
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 FROM Pub_Company a, Gsp_Company_License b
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                WHERE a.Companyid = b.Companyid
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  AND a.Companyid = v_Supplyid
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  AND b.Entryid = v_Entryid
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  AND b.Licensetypeid = p_Cur.Licensetypeid)*/
         (SELECT COUNT(1) Vv_Count
            FROM Pub_Company a, Gsp_Company_License b
           WHERE a.Companyid = b.Companyid
             AND a.Companyid = v_Supplyid
             AND b.Entryid = v_Entryid
             AND b.Licensetypeid = p_Cur.Licensetypeid
             AND b.Usestatus = 1
             AND b.Validenddate > SYSDATE) LOOP
          --IF p_Cur1.Usestatus = 1 AND p_Cur1.Validenddate > SYSDATE THEN
          IF p_Cur1.Vv_Count > 0 THEN
            Get_Str := '{' || '"entryid":"' || v_Entryid ||
                       '","entryname":"' || v_Entryname || '","supplyid":"' ||
                       v_Supplyid || '","supplyname":"' || v_Supplyname ||
                       '","licensename":"' || p_Cur.Licensename ||
                       '","status":"S","error_msg":"SUCCESS"}';
            Appmess := Appmess || Get_Str || ',';
            EXIT;
          ELSE
            Get_Str := '{' || '"entryid":"' || v_Entryid ||
                       '","entryname":"' || v_Entryname || '","supplyid":"' ||
                       v_Supplyid || '","supplyname":"' || v_Supplyname ||
                       '","licensename":"' || p_Cur.Licensename ||
                       '","status":"E","error_msg":"效期失效或者未启用"}';
            Appmess := Appmess || Get_Str || ',';
          END IF;
          v_Count := v_Count + 1;
        END LOOP;
      END LOOP;
    END LOOP;
    Appmess := '[' || Substr(Appmess, 0, Length(Appmess) - 1) || ']';
  END Po_Plan_Check_License_Sp;
  /*供应商法人委托书校验*/
  PROCEDURE Po_Check_Company_To_Agent_Sp(Datajson IN CLOB,
                                         Appmess  OUT CLOB) IS
    Get_Json     Json;
    Get_Jsonlist Json_List;
    CURSOR Agent_Cur(i_Supplyid NUMBER, i_Entryid NUMBER, i_Goodsid NUMBER) IS
      SELECT Nvl(b.Goodsid, 0) Goodsid, a.Ctrltype, a.Dateto
        FROM Zx_Pub_Company_To_Agent a, Zx_Pub_Agent_To_Goods b
       WHERE a.Seqid = b.Seqid(+)
         AND a.Companyid = i_Supplyid
         AND a.Entryid = i_Entryid
         AND Nvl(b.Goodsid, i_Goodsid) = i_Goodsid;
    TYPE Ag_Rec IS RECORD(
      Goodsid  NUMBER,
      Ctrltype NUMBER,
      Dateto   DATE);
    v_Cur_Rec    Ag_Rec;
    i            NUMBER;
    v_Entryid    NUMBER;
    v_Supplyid   NUMBER;
    v_Goodsid    NUMBER;
    v_Count      NUMBER;
    Get_Str      VARCHAR2(4000);
    v_Entryname  VARCHAR2(100);
    v_Supplyname VARCHAR2(100);
    v_Goodsname  VARCHAR2(100);
  BEGIN
  
    i            := 1;
    Get_Jsonlist := Json_List(Datajson);
    WHILE i <= Get_Jsonlist.Count LOOP
      Get_Json   := Json(Get_Jsonlist.Get(i));
      v_Entryid  := Get_Jsonnumber(Get_Json, 'entryid');
      v_Supplyid := Get_Jsonnumber(Get_Json, 'supplyid');
      v_Goodsid  := Get_Jsonnumber(Get_Json, 'goodsid');
      SELECT Pe.Entryname
        INTO v_Entryname
        FROM Pub_Entry Pe
       WHERE Pe.Entryid = v_Entryid;
      SELECT Ps.Supplyname
        INTO v_Supplyname
        FROM Pub_Supplyer Ps
       WHERE Ps.Supplyid = v_Supplyid;
      SELECT Peg.Goodsname
        INTO v_Goodsname
        FROM Pub_Entry_Goods_v Peg
       WHERE Peg.Entryid = v_Entryid
         AND Peg.Goodsid = v_Goodsid;
    
      SELECT COUNT(1)
        INTO v_Count
        FROM Zx_Pub_Company_To_Agent a, Zx_Pub_Agent_To_Goods b
       WHERE a.Seqid = b.Seqid(+)
         AND a.Companyid = v_Supplyid
         AND a.Entryid = v_Entryid
         AND Nvl(b.Goodsid, v_Goodsid) = v_Goodsid;
      IF v_Count = 0 THEN
        Get_Str := '{' || '"entryid":"' || v_Entryid || '","entryname":"' ||
                   v_Entryname || '","supplyid":"' || v_Supplyid ||
                   '","supplyname":"' || v_Supplyname || '","goodsid":"' ||
                   v_Goodsid || '","goodsname":"' || v_Goodsname ||
                   '","status":"E","error_msg":"供应商法人委托书失效或者未维护限定品种"}';
        Appmess := Appmess || Get_Str || ',';
      END IF;
      OPEN Agent_Cur(v_Supplyid, v_Entryid, v_Goodsid);
      LOOP
        FETCH Agent_Cur
          INTO v_Cur_Rec;
        EXIT WHEN Agent_Cur%NOTFOUND;
      
        IF (v_Cur_Rec.Ctrltype = 1 AND v_Cur_Rec.Goodsid = v_Goodsid AND
           v_Cur_Rec.Dateto > SYSDATE) OR
           (v_Cur_Rec.Ctrltype = 0 AND v_Cur_Rec.Dateto > SYSDATE) THEN
          Get_Str := '{' || '"entryid":"' || v_Entryid || '","entryname":"' ||
                     v_Entryname || '","supplyid":"' || v_Supplyid ||
                     '","supplyname":"' || v_Supplyname || '","goodsid":"' ||
                     v_Goodsid || '","goodsname":"' || v_Goodsname ||
                     '","status":"S","error_msg":"SUCCESS"}';
          Appmess := Appmess || Get_Str || ',';
          EXIT;
        ELSE
          Get_Str := '{' || '"entryid":"' || v_Entryid || '","entryname":"' ||
                     v_Entryname || '","supplyid":"' || v_Supplyid ||
                     '","supplyname":"' || v_Supplyname || '","goodsid":"' ||
                     v_Goodsid || '","goodsname":"' || v_Goodsname ||
                     '","status":"E","error_msg":"供应商法人委托书失效或者未维护限定品种"}';
          Appmess := Appmess || Get_Str || ',';
        END IF;
        EXIT WHEN Agent_Cur%NOTFOUND;
      END LOOP;
      CLOSE Agent_Cur;
      i := i + 1;
    END LOOP;
    Appmess := '[' || Substr(Appmess, 0, Length(Appmess) - 1) || ']';
  END Po_Check_Company_To_Agent_Sp;
  /*采购员委托书校验*/
  PROCEDURE Po_Check_Emp_Proxy_Sp(Datajson IN CLOB, Appmess OUT CLOB) IS
    Get_Json     Json;
    Get_Jsonlist Json_List;
  
    v_Count        NUMBER := 1;
    v_Count1       NUMBER;
    v_Entryid      NUMBER;
    v_Supplyid     NUMBER;
    v_Goodsid      NUMBER;
    v_Supplyerid   NUMBER;
    Get_Str        VARCHAR2(4000);
    v_Entryname    VARCHAR2(100);
    v_Supplyname   VARCHAR2(100);
    v_Goodsname    VARCHAR2(100);
    v_Supplyername VARCHAR2(100);
  BEGIN
  
    Get_Jsonlist := Json_List(Datajson);
    FOR i IN 1 .. Get_Jsonlist.Count LOOP
      Get_Json     := Json(Get_Jsonlist.Get(i));
      v_Entryid    := Get_Jsonnumber(Get_Json, 'entryid');
      v_Supplyid   := Get_Jsonnumber(Get_Json, 'supplyid');
      v_Goodsid    := Get_Jsonnumber(Get_Json, 'goodsid');
      v_Supplyerid := Get_Jsonnumber(Get_Json, 'supplyerid');
    
      SELECT Pe.Entryname
        INTO v_Entryname
        FROM Pub_Entry Pe
       WHERE Pe.Entryid = v_Entryid;
      SELECT Ps.Supplyname
        INTO v_Supplyname
        FROM Pub_Supplyer Ps
       WHERE Ps.Supplyid = v_Supplyid;
      SELECT Peg.Goodsname
        INTO v_Goodsname
        FROM Pub_Entry_Goods_v Peg
       WHERE Peg.Entryid = v_Entryid
         AND Peg.Goodsid = v_Goodsid;
      SELECT Pe.Employeename
        INTO v_Supplyername
        FROM Pub_Employee Pe
       WHERE Pe.Employeeid = v_Supplyerid;
      SELECT COUNT(1)
        INTO v_Count1
        FROM Pub_Emp_Proxy_Doc a, Pub_Emp_Proxy_Goods_Dtl b
       WHERE a.Proxydocid = b.Proxydocid
         AND a.Companyid = v_Supplyid
         AND a.Entryid = v_Entryid
         AND a.Employeeid = v_Supplyerid
         AND b.Goodsid = v_Goodsid;
    
      IF v_Count1 = 0 THEN
        Get_Str := '{' || '"entryid":"' || v_Entryid || '","entryname":"' ||
                   v_Entryname || '","supplyid":"' || v_Supplyid ||
                   '","supplyname":"' || v_Supplyname || '","goodsid":"' ||
                   v_Goodsid || '","goodsname":"' || v_Goodsname ||
                   '","supplyerid":"' || v_Supplyerid ||
                   '","supplyername":"' || v_Supplyername ||
                   '","status":"E","error_msg":"未维护采购员委托书或者已失效"}';
        Appmess := Appmess || Get_Str || ',';
      END IF;
      FOR Emp IN (SELECT Nvl(a.Enddate, SYSDATE) Enddate,
                         Nvl(b.Goodsid, 0) Goodsid
                    FROM Pub_Emp_Proxy_Doc a, Pub_Emp_Proxy_Goods_Dtl b
                   WHERE a.Proxydocid = b.Proxydocid
                     AND a.Companyid = v_Supplyid
                     AND a.Entryid = v_Entryid
                     AND a.Employeeid = v_Supplyerid
                     AND b.Goodsid = v_Goodsid) LOOP
      
        IF Emp.Goodsid = v_Goodsid AND
           Emp.Enddate > SYSDATE THEN
          Get_Str := '{' || '"entryid":"' || v_Entryid || '","entryname":"' ||
                     v_Entryname || '","supplyid":"' || v_Supplyid ||
                     '","supplyname":"' || v_Supplyname || '","goodsid":"' ||
                     v_Goodsid || '","goodsname":"' || v_Goodsname ||
                     '","supplyerid":"' || v_Supplyerid ||
                     '","supplyername":"' || v_Supplyername ||
                     '","status":"S","error_msg":"SUCCESS"}';
          Appmess := Appmess || Get_Str || ',';
          EXIT;
        ELSE
          Get_Str := '{' || '"entryid":"' || v_Entryid || '","entryname":"' ||
                     v_Entryname || '","supplyid":"' || v_Supplyid ||
                     '","supplyname":"' || v_Supplyname || '","goodsid":"' ||
                     v_Goodsid || '","goodsname":"' || v_Goodsname ||
                     '","supplyerid":"' || v_Supplyerid ||
                     '","supplyername":"' || v_Supplyername ||
                     '","status":"E","error_msg":"未维护采购员委托书或者已失效"}';
          Appmess := Appmess || Get_Str || ',';
        END IF;
      
      END LOOP;
      v_Count := v_Count + 1;
    END LOOP;
    Appmess := '[' || Substr(Appmess, 0, Length(Appmess) - 1) || ']';
  END Po_Check_Emp_Proxy_Sp;
  /*采购价目校验*/
  PROCEDURE Po_Check_Su_Price_Sp(Datajson IN CLOB, Appmess OUT CLOB) IS
    Get_Json     Json;
    Get_Jsonlist Json_List;
    --v_Count        NUMBER := 1;
    v_Count1       NUMBER;
    v_Count12      NUMBER;
    v_Count13      NUMBER;
    v_Entryid      NUMBER;
    v_Supplyid     NUMBER;
    v_Goodsid      NUMBER;
    v_Supplyerid   NUMBER;
    v_Agentid1     NUMBER;
    Get_Str        VARCHAR2(4000);
    v_Entryname    VARCHAR2(100);
    v_Supplyname   VARCHAR2(100);
    v_Goodsname    VARCHAR2(100);
    v_Supplyername VARCHAR2(100);
    v_Agentname    VARCHAR2(100);
  BEGIN
    Get_Jsonlist := Json_List(Datajson);
    FOR i IN 1 .. Get_Jsonlist.Count LOOP
      Get_Json     := Json(Get_Jsonlist.Get(i));
      v_Entryid    := Get_Jsonnumber(Get_Json, 'entryid');
      v_Supplyid   := Get_Jsonnumber(Get_Json, 'supplyid');
      v_Goodsid    := Get_Jsonnumber(Get_Json, 'goodsid');
      v_Supplyerid := Get_Jsonnumber(Get_Json, 'supplyerid');
      v_Agentid1   := Get_Jsonnumber(Get_Json, 'agentid');
    
      SELECT Pe.Entryname
        INTO v_Entryname
        FROM Pub_Entry Pe
       WHERE Pe.Entryid = v_Entryid;
      SELECT Ps.Supplyname
        INTO v_Supplyname
        FROM Pub_Supplyer Ps
       WHERE Ps.Supplyid = v_Supplyid;
      SELECT Peg.Goodsname
        INTO v_Goodsname
        FROM Pub_Entry_Goods_v Peg
       WHERE Peg.Entryid = v_Entryid
         AND Peg.Goodsid = v_Goodsid;
      SELECT Pe.Employeename
        INTO v_Supplyername
        FROM Pub_Employee Pe
       WHERE Pe.Employeeid = v_Supplyerid;
      SELECT Bad.Agentname
        INTO v_Agentname
        FROM Bms_Agent_Def Bad
       WHERE Bad.Agentid = v_Agentid1;
      SELECT COUNT(1)
        INTO v_Count1
        FROM Bms_Ebs_Su_Price_Catalog a
       WHERE a.Usestatus = 1
         AND a.Entryid = v_Entryid
         AND a.Goodsid = v_Goodsid
         AND a.Buyer = v_Supplyerid;
      IF v_Count1 = 0 THEN
        Get_Str := '{' || '"entryid":"' || v_Entryid || '","entryname":"' ||
                   v_Entryname || '","supplyid":"' || v_Supplyid ||
                   '","supplyname":"' || v_Supplyname || '","agentid":"' ||
                   v_Agentid1 || '","agentname":"' || v_Agentname ||
                   '","goodsid":"' || v_Goodsid || '","goodsname":"' ||
                   v_Goodsname || '","supplyerid":"' || v_Supplyerid ||
                   '","supplyername":"' || v_Supplyername ||
                   '","status":"E","error_msg":"采购价目未维护"}';
        Appmess := Appmess || Get_Str || ',';
      END IF;
      /*FOR Price_Cur IN (*/
      SELECT COUNT(1)
        INTO v_Count12
        FROM Bms_Ebs_Su_Price_Catalog a
       WHERE a.Usestatus = 1
         AND a.Entryid = v_Entryid
         AND a.Goodsid = v_Goodsid
         AND a.Buyer = v_Supplyerid
         AND a.Only_Item_Flag = 'Y'; /*) LOOP*/
      IF /*(Price_Cur.Buyer = v_Supplyerid AND
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           Price_Cur.Companyid = v_Supplyid AND
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           Price_Cur.Agentid = v_Agentid1 AND
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           Price_Cur.Only_Item_Flag = 'N') OR
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           (Price_Cur.Only_Item_Flag = 'Y' AND
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           Price_Cur.Buyer = v_Supplyerid)*/
       v_Count12 > 0 THEN
        Get_Str := '{' || '"entryid":"' || v_Entryid || '","entryname":"' ||
                   v_Entryname || '","supplyid":"' || v_Supplyid ||
                   '","supplyname":"' || v_Supplyname || '","agentid":"' ||
                   v_Agentid1 || '","agentname":"' || v_Agentname ||
                   '","goodsid":"' || v_Goodsid || '","goodsname":"' ||
                   v_Goodsname || '","supplyerid":"' || v_Supplyerid ||
                   '","supplyername":"' || v_Supplyername ||
                   '","status":"S","error_msg":"SUCCESS"}';
        Appmess := Appmess || Get_Str || ',';
        EXIT;
      ELSIF v_Count12 = 0
      --ELSE
       THEN
        SELECT COUNT(1)
          INTO v_Count13
          FROM Bms_Ebs_Su_Price_Catalog a
         WHERE
        
         a.Usestatus = 1
         AND a.Entryid = v_Entryid
         AND a.Goodsid = v_Goodsid
         AND a.Buyer = v_Supplyerid
         AND a.Companyid = v_Supplyid
         AND a.Agentid = v_Agentid1
         AND a.Only_Item_Flag = 'N';
        IF v_Count13 > 0 THEN
          Get_Str := '{' || '"entryid":"' || v_Entryid || '","entryname":"' ||
                     v_Entryname || '","supplyid":"' || v_Supplyid ||
                     '","supplyname":"' || v_Supplyname || '","agentid":"' ||
                     v_Agentid1 || '","agentname":"' || v_Agentname ||
                     '","goodsid":"' || v_Goodsid || '","goodsname":"' ||
                     v_Goodsname || '","supplyerid":"' || v_Supplyerid ||
                     '","supplyername":"' || v_Supplyername ||
                     '","status":"S","error_msg":"SUCCESS"}';
          Appmess := Appmess || Get_Str || ',';
          EXIT;
        END IF;
      ELSE
        Get_Str := '{' || '"entryid":"' || v_Entryid || '","entryname":"' ||
                   v_Entryname || '","supplyid":"' || v_Supplyid ||
                   '","supplyname":"' || v_Supplyname || '","agentid":"' ||
                   v_Agentid1 || '","agentname":"' || v_Agentname ||
                   '","goodsid":"' || v_Goodsid || '","goodsname":"' ||
                   v_Goodsname || '","supplyerid":"' || v_Supplyerid ||
                   '","supplyername":"' || v_Supplyername ||
                   '","status":"E","error_msg":"采购价目未维护"}';
        Appmess := Appmess || Get_Str || ',';
        /*Get_Str := '{' || '"entryid":"' || v_Entryid || '","entryname":"' ||
                   v_Entryname || '","supplyid":"' || v_Supplyid ||
                   '","supplyname":"' || v_Supplyname || '","agentid":"' ||
                   v_Agentid1 || '","agentname":"' || v_Agentname ||
                   '","goodsid":"' || v_Goodsid || '","goodsname":"' ||
                   v_Goodsname || '","supplyerid":"' || v_Supplyerid ||
                   '","supplyername":"' || v_Supplyername ||
                   '","status":"E","error_msg":"采购价目未维护"}';
        Appmess := Appmess || Get_Str || ',';*/
      END IF;
      --v_Count := v_Count + 1;
    END LOOP;
    Appmess := '[' || Substr(Appmess, 0, Length(Appmess) - 1) || ']';
  END Po_Check_Su_Price_Sp;
  /*采购发票超期校验*/
  PROCEDURE Po_Check_Su_Fpcq_Sp(Datajson IN CLOB, Appmess OUT CLOB) IS
    Get_Json     Json;
    Get_Jsonlist Json_List;
  
    v_Count      NUMBER := 1;
    v_Count1     NUMBER;
    v_Entryid    NUMBER;
    v_Supplyid   NUMBER;
    v_Goodsid    NUMBER;
    Get_Str      VARCHAR2(4000);
    v_Entryname  VARCHAR2(100);
    v_Supplyname VARCHAR2(100);
    v_Goodsname  VARCHAR2(100);
  BEGIN
    Get_Jsonlist := Json_List(Datajson);
    FOR i IN 1 .. Get_Jsonlist.Count LOOP
      Get_Json   := Json(Get_Jsonlist.Get(i));
      v_Entryid  := Get_Jsonnumber(Get_Json, 'entryid');
      v_Supplyid := Get_Jsonnumber(Get_Json, 'supplyid');
      v_Goodsid  := Get_Jsonnumber(Get_Json, 'goodsid');
      SELECT Pe.Entryname
        INTO v_Entryname
        FROM Pub_Entry Pe
       WHERE Pe.Entryid = v_Entryid;
      SELECT Ps.Supplyname
        INTO v_Supplyname
        FROM Pub_Supplyer Ps
       WHERE Ps.Supplyid = v_Supplyid;
      SELECT Peg.Goodsname
        INTO v_Goodsname
        FROM Pub_Entry_Goods_v Peg
       WHERE Peg.Entryid = v_Entryid
         AND Peg.Goodsid = v_Goodsid;
      SELECT COUNT(1)
        INTO v_Count1
        FROM Bms_Su_Doc a,
             Bms_Su_Dtl b,
             (SELECT d.Sudocdtlid, SUM(d.Total_Line) Total_Line
                FROM Bms_Su_Set_Doc c, Bms_Su_Set_Dtl d
               WHERE c.Susetdocid = d.Susetdocid
                 AND c.Supplyid = v_Supplyid
                 AND c.Entryid = v_Entryid
                 AND c.Usestatus = 1
                 AND d.Goodsid = v_Goodsid
               GROUP BY d.Sudocdtlid) e
       WHERE a.Sudocid = b.Sudocid
         AND b.Sudocdtlid = e.Sudocdtlid(+)
         AND b.Total_Line > Nvl(e.Total_Line, 0)
         AND a.Sutypeid = 1
         AND a.Entryid = v_Entryid
         AND a.Usestatus = 1
         AND b.Goodsid = v_Goodsid
         AND a.Supplyid = v_Supplyid;
      IF v_Count1 = 0 THEN
        Get_Str := '{' || '"entryid":"' || v_Entryid || '","entryname":"' ||
                   v_Entryname || '","supplyid":"' || v_Supplyid ||
                   '","supplyname":"' || v_Supplyname || '","goodsid":"' ||
                   v_Goodsid || '","goodsname":"' || v_Goodsname ||
                   '","status":"S","error_msg":"供应商发票货品未超期"}';
        Appmess := Appmess || Get_Str || ',';
      END IF;
      FOR Aa IN (SELECT Bb.Cqts,
                        (SELECT MAX(Zis.Lockdays)
                           FROM Zx_Invnolock_Supplyergoods Zis
                          WHERE Zis.Entryid = Bb.Entryid
                            AND Zis.Supplyid = Bb.Supplyid
                            AND Zis.Goodsid = Bb.Goodsid) Lockdays
                   FROM (SELECT SYSDATE - MIN(a.Credate) Cqts,
                                a.Entryid,
                                a.Supplyid,
                                b.Goodsid
                           FROM Bms_Su_Doc a,
                                Bms_Su_Dtl b,
                                (SELECT d.Sudocdtlid,
                                        SUM(d.Total_Line) Total_Line
                                   FROM Bms_Su_Set_Doc c, Bms_Su_Set_Dtl d
                                  WHERE c.Susetdocid = d.Susetdocid
                                    AND c.Supplyid = v_Supplyid
                                    AND c.Entryid = v_Entryid
                                    AND c.Usestatus = 1
                                    AND d.Goodsid = v_Goodsid
                                  GROUP BY d.Sudocdtlid) e
                          WHERE a.Sudocid = b.Sudocid
                            AND b.Sudocdtlid = e.Sudocdtlid(+)
                            AND b.Total_Line > Nvl(e.Total_Line, 0)
                            AND a.Sutypeid = 1
                            AND a.Entryid = v_Entryid
                            AND a.Usestatus = 1
                            AND b.Goodsid = v_Goodsid
                            AND a.Supplyid = v_Supplyid
                          GROUP BY a.Entryid, a.Supplyid, b.Goodsid) Bb) LOOP
        IF (Nvl(Aa.Lockdays, 0) >= 60) OR
           (Nvl(Aa.Lockdays, 0) < 60 AND Aa.Cqts <= 60) THEN
          Get_Str := '{' || '"entryid":"' || v_Entryid || '","entryname":"' ||
                     v_Entryname || '","supplyid":"' || v_Supplyid ||
                     '","supplyname":"' || v_Supplyname || '","goodsid":"' ||
                     v_Goodsid || '","goodsname":"' || v_Goodsname ||
                     '","status":"S","error_msg":"供应商发票货品未超期"}';
          Appmess := Appmess || Get_Str || ',';
        ELSE
          Get_Str := '{' || '"entryid":"' || v_Entryid || '","entryname":"' ||
                     v_Entryname || '","supplyid":"' || v_Supplyid ||
                     '","supplyname":"' || v_Supplyname || '","goodsid":"' ||
                     v_Goodsid || '","goodsname":"' || v_Goodsname ||
                     '","status":"E","error_msg":"有超60天未开发票采购明细"}';
          Appmess := Appmess || Get_Str || ',';
        END IF;
      END LOOP;
      v_Count := v_Count + 1;
    END LOOP;
    Appmess := '[' || Substr(Appmess, 0, Length(Appmess) - 1) || ']';
  END Po_Check_Su_Fpcq_Sp;
  /*供应商证照货品范围校验*/
  PROCEDURE Po_Check_Goods_License_Sp(Datajson IN CLOB, Appmess OUT CLOB) IS
    Get_Json     Json;
    Get_Jsonlist Json_List;
  
    v_Licensename  Gsp_License_Type.Licensename%TYPE;
    v_Validenddate DATE;
  
    --获取货品经营范围，剂型
    CURSOR Check_Goods_Cur(i_Entryid NUMBER, i_Goodsid NUMBER) IS
      SELECT a.Busiscope, a.Medicinetype --经营范围,剂型
        FROM Pub_Entry_Goods a
       WHERE a.Entryid = i_Entryid
         AND a.Goodsid = i_Goodsid;
  
    --经营范围cursor
    CURSOR Busiscope_Cur(i_Entryid NUMBER, i_Supplyid NUMBER) IS
      SELECT c.Licensetypeid, b.Rangectrl, d.Licensename
        FROM Pub_Entry_Supplyer a,
             Gsp_Category_Doc   b, --证照管控分类定义
             Gsp_Category_Dtl   c,
             Gsp_License_Type   d --企业证照类型管理
       WHERE a.Gspcategoryid = b.Categoryid
         AND b.Categoryid = c.Categoryid
         AND c.Licensetypeid = d.Licensetypeid
         AND b.Rangectrl = 1 --按照经营范围维护 1代表经营范围
         AND d.Rangeflag = 1 --是否含经营范围
         AND a.Supplyid = i_Supplyid
         AND a.Entryid = i_Entryid;
    --剂型cursor
    CURSOR Medicinetype_Cur(i_Entryid NUMBER, i_Supplyid NUMBER) IS
      SELECT c.Licensetypeid, b.Rangectrl, d.Licensename
        FROM Pub_Entry_Supplyer a,
             Gsp_Category_Doc   b,
             Gsp_Category_Dtl   c,
             Gsp_License_Type   d
       WHERE a.Gspcategoryid = b.Categoryid
         AND b.Categoryid = c.Categoryid
         AND c.Licensetypeid = d.Licensetypeid
         AND b.Rangectrl = 2 --经营范围控制  2代表剂型
         AND d.Rangeflag = 1 --是否含经营范围
         AND a.Supplyid = i_Supplyid
         AND a.Entryid = i_Entryid;
  
    v_Entryid      NUMBER;
    v_Supplyid     NUMBER;
    v_Goodsid      NUMBER;
    Get_Str        VARCHAR2(32767);
    v_Count        NUMBER;
    v_Count11      NUMBER;
    Vv_Licensename VARCHAR2(1000);
    v_Entryname    VARCHAR2(1000);
    v_Supplyname   VARCHAR2(1000);
    v_Goodsname    VARCHAR2(1000);
  
    v_Loop_Count NUMBER := 0;
  BEGIN
    Get_Jsonlist := Json_List(Datajson);
    FOR i IN 1 .. Get_Jsonlist.Count LOOP
      Get_Json   := Json(Get_Jsonlist.Get(i));
      v_Entryid  := Get_Jsonnumber(Get_Json, 'entryid');
      v_Supplyid := Get_Jsonnumber(Get_Json, 'supplyid');
      v_Goodsid  := Get_Jsonnumber(Get_Json, 'goodsid');
      SELECT Pe.Entryname
        INTO v_Entryname
        FROM Pub_Entry Pe
       WHERE Pe.Entryid = v_Entryid;
      SELECT Ps.Supplyname
        INTO v_Supplyname
        FROM Pub_Supplyer Ps
       WHERE Ps.Supplyid = v_Supplyid;
      SELECT Peg.Goodsname
        INTO v_Goodsname
        FROM Pub_Entry_Goods_v Peg
       WHERE Peg.Entryid = v_Entryid
         AND Peg.Goodsid = v_Goodsid;
      --根据货品经营范围，剂型来检查相关证照
      FOR Cg_Cur IN Check_Goods_Cur(v_Entryid, v_Goodsid) LOOP
      
        --首先检查经营范围
        --检查经营范围前 判断是否存在含有经营范围的证照缺失情况 v_Count = 0 代表不缺失；v_Count > 0 代表缺失
        SELECT COUNT(1)
          INTO v_Count
          FROM Pub_Entry_Supplyer a,
               Gsp_Category_Doc   b,
               Gsp_Category_Dtl   c,
               Gsp_License_Type   d
         WHERE a.Gspcategoryid = b.Categoryid
           AND b.Categoryid = c.Categoryid
           AND c.Licensetypeid = d.Licensetypeid
           AND d.Rangeflag = 1
           AND a.Supplyid = v_Supplyid
           AND a.Entryid = v_Entryid
           AND NOT EXISTS
         (SELECT 1
                  FROM Gsp_Company_License Tt
                 WHERE a.Supplyid = Tt.Companyid
                   AND a.Entryid = Tt.Entryid
                   AND c.Licensetypeid = Tt.Licensetypeid);
        IF v_Count > 0 THEN
          SELECT Listagg(d.Licensename, ',') Within GROUP(ORDER BY NULL) Licensename
            INTO Vv_Licensename
            FROM Pub_Entry_Supplyer a,
                 Gsp_Category_Doc   b,
                 Gsp_Category_Dtl   c,
                 Gsp_License_Type   d
           WHERE a.Gspcategoryid = b.Categoryid
             AND b.Categoryid = c.Categoryid
             AND c.Licensetypeid = d.Licensetypeid
             AND d.Rangeflag = 1
             AND a.Supplyid = v_Supplyid
             AND a.Entryid = v_Entryid
             AND NOT EXISTS
           (SELECT 1
                    FROM Gsp_Company_License Tt
                   WHERE a.Supplyid = Tt.Companyid
                     AND a.Entryid = Tt.Entryid
                     AND c.Licensetypeid = Tt.Licensetypeid);
          Get_Str := '{' || '"entryid":"' || v_Entryid || '","entryname":"' ||
                     v_Entryname || '","supplyid":"' || v_Supplyid ||
                     '","supplyname":"' || v_Supplyname || '","goodsid":"' ||
                     v_Goodsid || '","goodsname":"' || v_Goodsname ||
                     '","licensename":"' || v_Licensename ||
                     '","status":"E","error_msg":"证照缺失"}';
          Appmess := Appmess || Get_Str || ',';
          EXIT;
        ELSE
          --获取游标行数
          v_Loop_Count := 0;
          SELECT COUNT(1)
            INTO v_Count
            FROM Pub_Entry_Supplyer a,
                 Gsp_Category_Doc   b, --证照管控分类定义
                 Gsp_Category_Dtl   c,
                 Gsp_License_Type   d --企业证照类型管理
           WHERE a.Gspcategoryid = b.Categoryid
             AND b.Categoryid = c.Categoryid
             AND c.Licensetypeid = d.Licensetypeid
             AND b.Rangectrl = 1 --按照经营范围维护 1代表经营范围
             AND d.Rangeflag = 1 --是否含经营范围
             AND a.Supplyid = v_Supplyid
             AND a.Entryid = v_Entryid;
          FOR Bc_Cur IN Busiscope_Cur(v_Entryid, v_Supplyid) LOOP
            SELECT COUNT(1)
              INTO v_Count11
              FROM Gsp_Company_License    b,
                   Gsp_License_Type       d,
                   Gsp_Company_Managerage t
             WHERE b.Licensetypeid = d.Licensetypeid
               AND b.Licenseid = t.Licenseid
               AND d.Rangeflag = 1
               AND b.Usestatus = 1
               AND b.Companyid = v_Supplyid
               AND b.Entryid = v_Entryid
               AND t.Scopedefid = Cg_Cur.Busiscope
               AND b.Licensetypeid = Bc_Cur.Licensetypeid;
            v_Loop_Count := v_Loop_Count + 1;
            IF v_Count11 = 0 THEN
              Get_Str := Get_Str || ',' || '{' || '"entryid":"' ||
                         v_Entryid || '","entryname":"' || v_Entryname ||
                         '","supplyid":"' || v_Supplyid ||
                         '","supplyname":"' || v_Supplyname ||
                         '","goodsid":"' || v_Goodsid || '","goodsname":"' ||
                         v_Goodsname || '","licensename":"' ||
                         Bc_Cur.Licensename ||
                         '","status":"E","error_msg":"供应商证照失效或者没有维护经营范围"}';
            
              IF v_Loop_Count = v_Count THEN
                Appmess := Appmess || Get_Str || ',';
                EXIT;
              END IF;
            
            END IF;
            IF v_Count11 > 0 THEN
              SELECT d.Licensename, MAX(b.Validenddate)
                INTO v_Licensename, v_Validenddate
                FROM Gsp_Company_License    b,
                     Gsp_License_Type       d,
                     Gsp_Company_Managerage t
               WHERE b.Licensetypeid = d.Licensetypeid
                 AND b.Licenseid = t.Licenseid
                 AND d.Rangeflag = 1
                 AND b.Usestatus = 1
                 AND b.Companyid = v_Supplyid
                 AND b.Entryid = v_Entryid
                 AND t.Scopedefid = Cg_Cur.Busiscope
                 AND b.Licensetypeid = Bc_Cur.Licensetypeid
               GROUP BY d.Licensename;
              IF v_Validenddate > SYSDATE THEN
                Get_Str := '{' || '"entryid":"' || v_Entryid ||
                           '","entryname":"' || v_Entryname ||
                           '","supplyid":"' || v_Supplyid ||
                           '","supplyname":"' || v_Supplyname ||
                           '","goodsid":"' || v_Goodsid ||
                           '","goodsname":"' || v_Goodsname ||
                           '","licensename":"' || v_Licensename ||
                           '","status":"S"}';
                Appmess := Appmess || Get_Str || ',';
                EXIT;
              ELSE
                Get_Str := '{' || '"entryid":"' || v_Entryid ||
                           '","entryname":"' || v_Entryname ||
                           '","supplyid":"' || v_Supplyid ||
                           '","supplyname":"' || v_Supplyname ||
                           '","goodsid":"' || v_Goodsid ||
                           '","goodsname":"' || v_Goodsname ||
                           '","licensename":"' || v_Licensename ||
                           '","status":"E","error_msg":"供应商证照已失效"}';
                Appmess := Appmess || Get_Str || ',';
              END IF;
            END IF;
          END LOOP;
        END IF;
      
        --检查剂型前 判断是否存在含有经营范围的证照缺失情况 v_Count = 0 代表不缺失；v_Count > 0 代表缺失
        SELECT COUNT(1)
          INTO v_Count
          FROM Pub_Entry_Supplyer a,
               Gsp_Category_Doc   b,
               Gsp_Category_Dtl   c,
               Gsp_License_Type   d
         WHERE a.Gspcategoryid = b.Categoryid
           AND b.Categoryid = c.Categoryid
           AND c.Licensetypeid = d.Licensetypeid
           AND d.Rangeflag = 1
           AND a.Supplyid = v_Supplyid
           AND a.Entryid = v_Entryid
           AND NOT EXISTS
         (SELECT 1
                  FROM Gsp_Company_License Tt
                 WHERE a.Supplyid = Tt.Companyid
                   AND a.Entryid = Tt.Entryid
                   AND c.Licensetypeid = Tt.Licensetypeid);
        IF v_Count > 0 THEN
          SELECT Listagg(d.Licensename, ',') Within GROUP(ORDER BY NULL) Licensename
            INTO Vv_Licensename
            FROM Pub_Entry_Supplyer a,
                 Gsp_Category_Doc   b,
                 Gsp_Category_Dtl   c,
                 Gsp_License_Type   d
           WHERE a.Gspcategoryid = b.Categoryid
             AND b.Categoryid = c.Categoryid
             AND c.Licensetypeid = d.Licensetypeid
             AND d.Rangeflag = 1
             AND a.Supplyid = v_Supplyid
             AND a.Entryid = v_Entryid
             AND NOT EXISTS
           (SELECT 1
                    FROM Gsp_Company_License Tt
                   WHERE a.Supplyid = Tt.Companyid
                     AND a.Entryid = Tt.Entryid
                     AND c.Licensetypeid = Tt.Licensetypeid);
          Get_Str := '{' || '"entryid":"' || v_Entryid || '","entryname":"' ||
                     v_Entryname || '","supplyid":"' || v_Supplyid ||
                     '","supplyname":"' || v_Supplyname || '","goodsid":"' ||
                     v_Goodsid || '","goodsname":"' || v_Goodsname ||
                     '","licensename":"' || Vv_Licensename ||
                     '","status":"E","error_msg":"证照缺失"}';
          Appmess := Appmess || Get_Str || ',';
          EXIT;
        ELSE
          v_Loop_Count := 0;
          --获取游标行数
          SELECT COUNT(1)
            INTO v_Count
            FROM Pub_Entry_Supplyer a,
                 Gsp_Category_Doc   b,
                 Gsp_Category_Dtl   c,
                 Gsp_License_Type   d
           WHERE a.Gspcategoryid = b.Categoryid
             AND b.Categoryid = c.Categoryid
             AND c.Licensetypeid = d.Licensetypeid
             AND b.Rangectrl = 2 --经营范围控制  2代表剂型
             AND d.Rangeflag = 1 --是否含经营范围
             AND a.Supplyid = v_Supplyid
             AND a.Entryid = v_Entryid;
          --其次检查剂型 检查货品的剂型 是否在供应商的证照剂型范围内
          FOR Mc_Cur IN Medicinetype_Cur(v_Entryid, v_Supplyid) LOOP
            SELECT COUNT(1)
              INTO v_Count11
              FROM Gsp_Company_License    b,
                   Gsp_License_Type       d,
                   Gsp_Company_Managerage t
             WHERE b.Licensetypeid = d.Licensetypeid
               AND b.Licenseid = t.Licenseid
               AND d.Rangeflag = 1
               AND b.Usestatus = 1
               AND b.Companyid = v_Supplyid
               AND b.Entryid = v_Entryid
               AND t.Medicinetype = Cg_Cur.Medicinetype
               AND b.Licensetypeid = Mc_Cur.Licensetypeid;
            v_Loop_Count := v_Loop_Count + 1;
            IF v_Count11 = 0 THEN
              Get_Str := Get_Str || ',' || '{' || '"entryid":"' ||
                         v_Entryid || '","entryname":"' || v_Entryname ||
                         '","supplyid":"' || v_Supplyid ||
                         '","supplyname":"' || v_Supplyname ||
                         '","goodsid":"' || v_Goodsid || '","goodsname":"' ||
                         v_Goodsname || '","licensename":"' ||
                         Mc_Cur.Licensename ||
                         '","status":"E","error_msg":"供应商证照失效或者没有维护经营范围"}';
            
              IF v_Loop_Count = v_Count THEN
                Appmess := Appmess || Get_Str || ',';
                EXIT;
              END IF;
            
            END IF;
            IF v_Count11 > 0 THEN
              SELECT d.Licensename, MAX(b.Validenddate)
                INTO v_Licensename, v_Validenddate
                FROM Gsp_Company_License    b,
                     Gsp_License_Type       d,
                     Gsp_Company_Managerage t
               WHERE b.Licensetypeid = d.Licensetypeid
                 AND b.Licenseid = t.Licenseid
                 AND d.Rangeflag = 1
                 AND b.Usestatus = 1
                 AND b.Companyid = v_Supplyid
                 AND b.Entryid = v_Entryid
                 AND t.Medicinetype = Cg_Cur.Medicinetype
                 AND b.Licensetypeid = Mc_Cur.Licensetypeid
               GROUP BY d.Licensename;
              IF v_Validenddate > SYSDATE THEN
                Get_Str := '{' || '"entryid":"' || v_Entryid ||
                           '","entryname":"' || v_Entryname ||
                           '","supplyid":"' || v_Supplyid ||
                           '","supplyname":"' || v_Supplyname ||
                           '","goodsid":"' || v_Goodsid ||
                           '","goodsname":"' || v_Goodsname ||
                           '","licensename":"' || v_Licensename ||
                           '","status":"S"}';
                Appmess := Appmess || Get_Str || ',';
                EXIT;
              ELSE
                Get_Str := '{' || '"entryid":"' || v_Entryid ||
                           '","entryname":"' || v_Entryname ||
                           '","supplyid":"' || v_Supplyid ||
                           '","supplyname":"' || v_Supplyname ||
                           '","goodsid":"' || v_Goodsid ||
                           '","goodsname":"' || v_Goodsname ||
                           '","licensename":"' || v_Licensename ||
                           '","status":"E","error_msg":"供应商证照已失效"}';
                Appmess := Appmess || Get_Str || ',';
              
              END IF;
            END IF;
          END LOOP;
        END IF;
      END LOOP;
    
    END LOOP;
    Appmess := '[' || Substr(Appmess, 0, Length(Appmess) - 1) || ']';
  END Po_Check_Goods_License_Sp;

  /*货品校验*/
  PROCEDURE Po_Check_Goods_Status_Sp(Datajson IN CLOB, Appmess OUT CLOB) IS
    Get_Json     Json;
    Get_Jsonlist Json_List;
  
    v_Entryid NUMBER;
    v_Goodsid NUMBER;
  
    v_Count NUMBER;
  
    v_Entryname VARCHAR2(1000);
    v_Goodsname VARCHAR2(1000);
    Get_Str     VARCHAR2(32767);
  BEGIN
    Get_Jsonlist := Json_List(Datajson);
    FOR i IN 1 .. Get_Jsonlist.Count LOOP
      Get_Json  := Json(Get_Jsonlist.Get(i));
      v_Entryid := Get_Jsonnumber(Get_Json, 'entryid');
      v_Goodsid := Get_Jsonnumber(Get_Json, 'goodsid');
    
      SELECT COUNT(1)
        INTO v_Count
        FROM Pub_Entry_Goods Peg
       WHERE Peg.Entryid = v_Entryid
         AND Peg.Goodsid = v_Goodsid
         AND Peg.Gspusestatus = 1
         AND Peg.Suuesstatus = 1;
    
      IF v_Count = 0 THEN
      
        SELECT MAX(Pe.Entryname)
          INTO v_Entryname
          FROM Pub_Entry Pe
         WHERE Pe.Entryid = v_Entryid;
      
        SELECT MAX(Peg.Goodsname)
          INTO v_Goodsname
          FROM Pub_Entry_Goods_v Peg
         WHERE Peg.Entryid = v_Entryid
           AND Peg.Goodsid = v_Goodsid;
      
        Get_Str := '{' || '"entryid":"' || v_Entryid || '","entryname":"' ||
                   v_Entryname || '","goodsid":"' || v_Goodsid ||
                   '","goodsname":"' || v_Goodsname ||
                   '","status":"E","error_msg":"货品无效"}';
        Appmess := Appmess || Get_Str || ',';
      END IF;
    END LOOP;
    IF Appmess IS NULL THEN
      Get_Str := '{' || '"status":"S","error_msg":"SUCCESS"}';
      Appmess := Appmess || Get_Str || ',';
      --Appmess := '[' || Substr(Appmess, 0, Length(Appmess) - 1) || ']';
    END IF;
    Appmess := '[' || Substr(Appmess, 0, Length(Appmess) - 1) || ']';
  END;

  /***
  采购订单临时转计划
  ***/
  PROCEDURE Po_Tmp_To_Plan_Sp IS
  
    CURSOR Po_Doc_Tmp IS
      SELECT * FROM Bms_Su_Con_Doc_Tmp WHERE Status = 0;
    CURSOR Po_Dtl_Tmp(p_Suconid NUMBER) IS
      SELECT * FROM Bms_Su_Con_Dtl_Tmp s WHERE s.Suconid = p_Suconid;
  
    v_Taxrate             Bms_Su_Plan.Tax_Rate%TYPE; --税率
    v_Unitprice           Bms_Su_Plan.Unitprice%TYPE; --单价
    v_Line_Id             Bms_Su_Plan.Line_Id%TYPE; --采购价目明细id
    v_Paylimit            Bms_Su_Plan.Paylimit%TYPE; --付款账期
    v_Settletypeid        Bms_Su_Plan.Paymethod%TYPE; --付款方式
    v_Stockqty            Bms_Su_Plan.Stqty%TYPE; --库存数量
    v_Upqty               Bms_Su_Plan.Upqty%TYPE; --上限数量
    v_Downqty             Bms_Su_Plan.Downqty%TYPE; --上限数量
    v_Paydate_Choice_Code Bms_Su_Plan.Paymethod%TYPE; --承付模式
    v_Lastthreemonthsaqty Bms_Su_Con_Dtl.Lastthreemonthsaqty%TYPE; --近三月销量
    v_Avgdayqty           Bms_Su_Plan.Avgdayqty%TYPE; --日均销量
  BEGIN
    FOR Po_Header_Cur IN Po_Doc_Tmp LOOP
      INSERT INTO Bms_Su_Plan_Doc
        (Plandocid,
         Credate,
         Entryid,
         Inputmanid,
         Wfusestatus,
         Wfprocess,
         Wfmemo,
         Usestatus,
         Comefrom)
      VALUES
        (Po_Header_Cur.Suconid,
         Po_Header_Cur.Credate,
         Po_Header_Cur.Entryid,
         Po_Header_Cur.Inputmanid,
         0,
         NULL,
         NULL,
         2,
         11);
      FOR Po_Line_Cur IN Po_Dtl_Tmp(Po_Header_Cur.Suconid) LOOP
      
        --库存数量
        SELECT MAX(a.Stqty)
          INTO v_Stockqty
          FROM Bms_Calc_Busi_Stqty_v a
         WHERE a.Entryid = Po_Header_Cur.Entryid
           AND a.Goodsid = Po_Line_Cur.Goodsid;
        --上限数量
        SELECT MAX(s.Upqty)
          INTO v_Upqty
          FROM Bms_Busi_Dtl s
         WHERE s.Entryid = Po_Header_Cur.Entryid
           AND s.Goodsid = Po_Line_Cur.Goodsid;
        --下限数量
        SELECT MAX(s.Downqty)
          INTO v_Downqty
          FROM Bms_Busi_Dtl s
         WHERE s.Entryid = Po_Header_Cur.Entryid
           AND s.Goodsid = Po_Line_Cur.Goodsid;
      
        --近三月销量
        SELECT SUM(Sd.Goodsqty)
          INTO v_Lastthreemonthsaqty
          FROM Bms_Sa_Doc Bsd, Bms_Sa_Dtl Sd
         WHERE Bsd.Salesid = Sd.Salesid
           AND Bsd.Credate > Add_Months(SYSDATE, -3)
           AND Bsd.Entryid = Po_Header_Cur.Entryid
           AND Sd.Goodsid = Po_Line_Cur.Goodsid;
        --日均销量
        v_Avgdayqty := v_Lastthreemonthsaqty / 90;
        IF Po_Line_Cur.Unitprice IS NULL THEN
          --价格、税率、付款账期
          SELECT MAX(a.Unit_Price),
                 MAX(a.Tax_Code),
                 MAX(a.Terms),
                 MAX(a.Payment_Method),
                 MAX(a.Line_Id),
                 MAX(a.Paydate_Choice_Code)
            INTO v_Unitprice,
                 v_Taxrate,
                 v_Paylimit,
                 v_Settletypeid,
                 v_Line_Id,
                 v_Paydate_Choice_Code
            FROM Bms_Ebs_Su_Price_Catalog a
           WHERE a.Usestatus = 1
             AND a.Entryid = Po_Header_Cur.Entryid
             AND a.Goodsid = Po_Line_Cur.Goodsid
             AND a.Buyer = Po_Header_Cur.Supplyerid
             AND a.Companyid = Po_Header_Cur.Supplyid
             AND a.Agentid = Po_Header_Cur.Agentid
             AND a.Only_Item_Flag = 'N'
             AND Trunc(SYSDATE) BETWEEN Trunc(a.Effective_Start_Date) AND
                 Trunc(Nvl(a.Effective_End_Date, SYSDATE + 1));
          IF v_Unitprice IS NULL THEN
            SELECT MAX(a.Unit_Price),
                   MAX(a.Tax_Code),
                   MAX(a.Terms),
                   MAX(a.Payment_Method),
                   MAX(a.Line_Id),
                   MAX(a.Paydate_Choice_Code)
              INTO v_Unitprice,
                   v_Taxrate,
                   v_Paylimit,
                   v_Settletypeid,
                   v_Line_Id,
                   v_Paydate_Choice_Code
              FROM Bms_Ebs_Su_Price_Catalog a
             WHERE a.Usestatus = 1
               AND a.Entryid = Po_Header_Cur.Entryid
               AND a.Goodsid = Po_Line_Cur.Goodsid
               AND a.Only_Item_Flag = 'Y'
               AND a.Buyer = Po_Header_Cur.Supplyerid
               AND Trunc(SYSDATE) BETWEEN Trunc(a.Effective_Start_Date) AND
                   Trunc(Nvl(a.Effective_End_Date, SYSDATE + 1));
          END IF;
        ELSE
          v_Unitprice := Po_Line_Cur.Unitprice;
        END IF;
      
        INSERT INTO Bms_Su_Plan
          (Planid,
           Goodsid,
           Supplyid,
           Supplyerid,
           Planqty,
           Plandate,
           Goodsqty,
           Unitprice,
           Arrivedate,
           Paylimit,
           Clause,
           Memo,
           Usestatus,
           Sucondtlid,
           Goodsuseqty,
           Empid,
           Protocaldtlid,
           Agentid,
           Plandocid,
           Invalidmanid,
           Invaliddate,
           Askpriceid,
           Sourceid,
           Oosrecid,
           Paymethod,
           Avgdayqty,
           Stqty,
           Payperiod,
           Upqty,
           Downqty,
           Settletypeid,
           Tax_Rate,
           Zx_Agentid,
           Line_Id,
           Approvemanid,
           Approvedate)
        VALUES
          (Po_Line_Cur.Sucondtlid,
           Po_Line_Cur.Goodsid,
           Po_Header_Cur.Supplyid,
           Po_Header_Cur.Supplyerid,
           NULL,
           NULL,
           Po_Line_Cur.Goodsuseqty,
           v_Unitprice,
           NULL,
           v_Paylimit,
           NULL,
           NULL,
           2,
           NULL,
           NULL,
           NULL,
           NULL,
           Po_Header_Cur.Agentid,
           Po_Header_Cur.Suconid,
           NULL,
           NULL,
           NULL,
           NULL,
           NULL,
           v_Paydate_Choice_Code, --承付模式 默认1
           v_Avgdayqty,
           v_Stockqty,
           NULL,
           v_Upqty,
           v_Downqty,
           v_Settletypeid, --付款方式 默认5,
           v_Taxrate,
           Po_Header_Cur.Zx_Agentid,
           v_Line_Id,
           NULL,
           NULL);
      END LOOP;
      UPDATE Bms_Su_Con_Doc_Tmp
         SET Status = 1
       WHERE Suconid = Po_Header_Cur.Suconid;
    END LOOP;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
  END;
END Hn_Po_Plan_Source_Pkg;
