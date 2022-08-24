CREATE OR REPLACE PACKAGE BODY HRHNPROD.Hn_Po_Plan_Source_Pkg IS

  FUNCTION Get_Jsonnumber(Get_Json Json, Dataname IN VARCHAR2)
    RETURN VARCHAR2 IS
  BEGIN
    RETURN Nvl(Json_Ext.Get_Number(Get_Json, Dataname),
               Json_Ext.Get_String(Get_Json, Dataname));
  END;

  /***
  �ƻ�����ȡ����Դ
  ***/
  PROCEDURE Po_Plan_Source_Data_Sp(p_Entryid IN NUMBER DEFAULT 9,
                                   p_Goodsid IN NUMBER DEFAULT NULL) IS
    CURSOR Goods_Cur IS
      SELECT *
        FROM Po_Plan_Source_Data_Tl s
       WHERE s.Entryid = p_Entryid
         AND s.Goodsid = Nvl(p_Goodsid, s.Goodsid);
  
    v_Count        NUMBER;
    v_Sales_Order  NUMBER; --���������۶�����Ŀ��
    v_Sales_Count1 NUMBER; --����������1
    v_Sales_Count2 NUMBER; --����������2
    v_Sales_Count3 NUMBER; --����������3
  
    --v_Last_Sales_Count NUMBER; --ȥ��ͬ������ 
    --v_Last_Po_Count    NUMBER; --ȥ��ͬ�ڲɹ���
    v_Po_In  NUMBER; --ȥ��ͬ�ڲɹ�������
    v_Po_Out NUMBER; --ȥ��ͬ�ڲɹ��˻���
    --v_Avg_Po_Count     NUMBER; --�¾��ɹ���
  
    v_Current_Sales_Count NUMBER; --����������
    v_Avg_Sales_Count     NUMBER; --��ƽ������
  
    v_Goodsqty     NUMBER; --��ǰ���
    v_Goodsqty_Use NUMBER; --�������
    --v_Plan_Qty     NUMBER; --���ռƻ�
    v_Online_Qty NUMBER; --15����;����
  
    v_Supplyid   VARCHAR2(32767);
    v_Supplyname VARCHAR2(32767);
  
    v_Exists_Conversion NUMBER; --�Ƿ����ת������
  BEGIN
    IF p_Goodsid IS NULL THEN
      EXECUTE IMMEDIATE 'truncate table Po_Plan_Source_Data_Tl';
    ELSE
      DELETE FROM Po_Plan_Source_Data_Tl s
       WHERE s.Entryid = p_Entryid
         AND s.Goodsid = p_Goodsid;
    END IF;
    --������ϻ��������Ļ�Ʒ��Ϣ
    INSERT INTO Po_Plan_Source_Data_Tl
      (Entryid,
       Goodsno, --��Ʒ����
       Goodsid, --��ƷID
       Goodsname, --ͨ����
       Currencyname, --��Ʒ��
       Goodstype, --���
       Goodsunit, --��С��λ
       Large_Tranfer_Rate, --����
       Supplytaxrate, --˰��
       Price_Tax, -- ��˰����
       Price_Hosp, --ҽԺ���Ƽ۸�
       Goodsmemo, --��Ʒ��ע
       Bidnumber, --�б���ˮ��
       Supplyerid, --�ɹ�Ա
       Supplyername, --�ɹ�Ա
       Factoryid, --��������id
       Factoryname, --��������
       Goodsattribution, --��Ʒ������
       Businessman, --������ϵ��
       Businessphone, --������ϵ��ʽ
       Clinicalman, --������ϵ��2
       Clinicalphone, --������ϵ��ʽ2
       Supplyman, --������ϵ��
       Supplyphone, --������ϵ��ʽ
       Payment_Method, --���ʽ
       Paydate_Choice_Code, --����������
       Terms) --����
      SELECT Peg.Entryid,
             Peg.Goodsno, --��Ʒ����
             Peg.Goodsid, --��ƷID
             Peg.Goodsname, --ͨ����
             Peg.Currencyname, --��Ʒ��
             Peg.Goodstype, --���
             Peg.Goodsunit, --��С��λ
             Peg.Large_Tranfer_Rate, --����
             Peg.Supplytaxrate, --˰��
             Pc1.Specify_Price Price_Tax, -- ��˰����
             Pc2.Specify_Price Price_Hosp, --ҽԺ���Ƽ۸�
             Peg.Goodsmemo, --��Ʒ��ע
             Peg.Bidnumber, --�б���ˮ��
             Peg.Supplyerid, --�ɹ�Աid
             Peg.Supplyername, --�ɹ�Ա
             Peg.Factoryid, --��������id
             Peg.Factoryname, --��������
             Peg.Goodsattribution, --��Ʒ������
             Peg.Businessman, --������ϵ��
             Peg.Businessphone, --������ϵ��ʽ
             Peg.Clinicalman, --������ϵ��2
             Peg.Clinicalphone, --������ϵ��ʽ2
             Peg.Supplyman, --������ϵ��
             Peg.Supplyphone, --������ϵ��ʽ
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
                  AND St.Storagename LIKE '���Ϲ�˾�ϸ��%'))
         AND Peg.Entryid = Nvl(p_Entryid, Peg.Entryid)
         AND Peg.Goodsid = Nvl(p_Goodsid, Peg.Goodsid)
         AND Peg.Suuesstatus = 1
         AND Peg.Gspusestatus = 1;
    FOR Rec_Goods IN Goods_Cur LOOP
      --���۶�����Ŀ��
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
      --����1
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
      --����2
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
      --����3
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
      --ȥ��ͬ������
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
    
      /*      --ȥ��ͬ�ڲɹ���
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
      --�ɹ���������
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
      --�ɹ��˻�����
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
      --����������
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
      -- �¾�����
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
      /*      --�¾��ɹ���
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
      --�ɹ���������
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
      --�ɹ��˻�����
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
      --��ǰ�������
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
         AND St.Storagename LIKE '���Ϲ�˾�ϸ��%';
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
           AND St.Storagename LIKE '���Ϲ�˾�ϸ��%';
      END IF;
      --�������
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
      --�����귢��ҵ��Ĺ�Ӧ��
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
      --���ȹ���ʱ����Ϊ��
      IF Lengthb(v_Supplyname) > 4000 THEN
        v_Supplyname := NULL;
        v_Supplyid   := NULL;
      END IF;
    
      --���ռƻ�
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
      --15����;����
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
         SET a.Sales_Order  = Nvl(v_Sales_Order, 0), --����������
             a.Sales_Count1 = Nvl(v_Sales_Count1, 0), --����������1
             a.Sales_Count2 = Nvl(v_Sales_Count2, 0), --����������2
             a.Sales_Count3 = Nvl(v_Sales_Count3, 0), --����������3
             --a.Last_Sales_Count    = v_Last_Sales_Count, --ȥ��ͬ������
             --a.Last_Po_Count       = v_Last_Po_Count, --ȥ��ͬ�ڲɹ���
             a.Current_Sales_Count = Nvl(v_Current_Sales_Count, 0), --����������
             a.Avg_Sales_Count     = Nvl(v_Avg_Sales_Count, 0), --��ƽ������
             a.Goodsqty            = Nvl(v_Goodsqty, 0), --��ǰ���
             a.Goodsqty_Use        = Nvl(v_Goodsqty_Use, 0), --�������
             --a.Plan_Qty            = v_Plan_Qty, --���ռƻ�
             a.Online_Qty = Nvl(v_Online_Qty, 0), --15����;����
             --a.Avg_Po_Count = v_Avg_Po_Count, --�¾��ɹ���
             a.Supplyid   = v_Supplyid, --��Ӧ��id
             a.Supplyname = v_Supplyname --��Ӧ��
       WHERE a.Entryid = Rec_Goods.Entryid
         AND a.Goodsid = Rec_Goods.Goodsid;
    
      v_Sales_Order  := 0; --����������
      v_Sales_Count1 := 0; --����������1
      v_Sales_Count2 := 0; --����������2
      v_Sales_Count3 := 0; --����������3
      --v_Last_Sales_Count    := NULL; --ȥ��ͬ������
      --v_Last_Po_Count       := NULL; --ȥ��ͬ�ڲɹ���
      v_Current_Sales_Count := NULL; --����������
      v_Avg_Sales_Count     := NULL; --��ƽ������
      v_Goodsqty            := NULL; --��ǰ���
      v_Goodsqty_Use        := NULL; --�������
      --v_Plan_Qty            := NULL; --���ռƻ�
      v_Online_Qty := NULL;
      v_Po_In      := NULL;
      v_Po_Out     := NULL;
      v_Supplyid   := NULL;
      v_Supplyname := NULL;
    
    END LOOP;
    COMMIT;
  END;
  /*
  �ɹ�������ʱת��ʽ
  */
  PROCEDURE Po_Tmp_To_Formal_Sp IS
    CURSOR Po_Doc_Tmp IS
      SELECT * FROM Bms_Su_Con_Doc_Tmp WHERE Status = 0;
    CURSOR Po_Dtl_Tmp(p_Suconid NUMBER) IS
      SELECT * FROM Bms_Su_Con_Dtl_Tmp s WHERE s.Suconid = p_Suconid;
    --�����ֶ�
    v_Supplyname Bms_Su_Con_Doc.Supplyname%TYPE; --��Ӧ������
    v_Signman    Bms_Su_Con_Doc.Signman%TYPE;
    v_Total      Bms_Su_Con_Doc.Total%TYPE; --�ܽ��
    v_Storerid   Bms_Su_Con_Doc.Storageid%TYPE; --�ֿ�ID
    v_Storageid  Bms_Su_Con_Doc.Storageid%TYPE; --������ID 
    v_Deptid     Bms_Su_Con_Doc.Deptid%TYPE; --ҵ����id
    v_Addressid  Bms_Su_Con_Doc.Addressid%TYPE; --��Ӧ�̵�ַID
  
    v_Goodsdtlid          Bms_Su_Con_Dtl.Goodsdtlid%TYPE; --��Ʒ���װid
    v_Goodsuseunit        Bms_Su_Con_Dtl.Goodsuseunit%TYPE; --ʹ�õ�λ
    v_Taxrate             Bms_Su_Con_Dtl.Taxrate%TYPE; --˰��
    v_Unitprice           Bms_Su_Con_Dtl.Unitprice%TYPE; --����
    v_Total_Line          Bms_Su_Con_Dtl.Total_Line%TYPE; --���
    v_Lastprice           Bms_Su_Con_Dtl.Lastprice%TYPE; --�ϴμ۸�
    v_Lowestprice         Bms_Su_Con_Dtl.Lowestprice%TYPE; --��ͽ���
    v_Supplylastprice     Bms_Su_Con_Dtl.Supplylastprice%TYPE; --�˹�Ӧ���������
    v_Paylimit            Bms_Su_Con_Dtl.Paylimit%TYPE; --��������
    v_Settletypeid        Bms_Su_Con_Dtl.Settletypeid%TYPE; --���ʽ
    v_Zx_Bigpacageqty     Bms_Su_Con_Dtl.Zx_Bigpacageqty%TYPE; --���װ����
    v_Line_Id             Bms_Su_Con_Dtl.Line_Id%TYPE; --�ɹ���Ŀ��ϸid
    v_Uplimitqty          Bms_Su_Con_Dtl.Uplimitqty%TYPE; --��������
    v_Stockqty            Bms_Su_Con_Dtl.Stockqty%TYPE; --�������
    v_Costprice           Bms_Su_Con_Dtl.Costprice%TYPE; --�ɱ�����
    v_Cost                Bms_Su_Con_Dtl.Cost%TYPE; --�ɱ����
    v_Lastthreemonthsaqty Bms_Su_Con_Dtl.Lastthreemonthsaqty%TYPE; --����������
    v_Avgdayqty           Bms_Su_Con_Dtl.Avgdayqty%TYPE; --�վ�����
    v_Sanotioqty          Bms_Su_Con_Dtl.Sanotioqty%TYPE; --����δ��������
    v_Twogoodsattribute   Bms_Su_Con_Dtl.Twogoodsattribute%TYPE; --��Ʊ������
    v_Zxgoodstype         Bms_Su_Con_Dtl.Zxgoodstype%TYPE; --��Ʒ��Ʊ������
    v_Usepacksize         Bms_Su_Con_Dtl.Usepacksize%TYPE; --ʹ�õ�λ��С
    v_Cansaledays         Bms_Su_Con_Dtl.Cansaledays%TYPE; --��������
    v_Upqty               Bms_Su_Con_Dtl.Upqty%TYPE; --�ɲɹ�����
    v_Commoditytype       Pub_Entry_Goods.Commoditytype%TYPE; --��Ʒ����
    v_Online_Qty          NUMBER(16, 6); --15����;����
  BEGIN
    FOR Po_Header_Cur IN Po_Doc_Tmp LOOP
      --��Ӧ������
      SELECT MAX(Ps.Supplyname)
        INTO v_Supplyname
        FROM Pub_Supplyer Ps
       WHERE Ps.Supplyid = Po_Header_Cur.Supplyid;
      --ǩԼ��
      SELECT MAX(Pe.Employeename)
        INTO v_Signman
        FROM Pub_Employee Pe
       WHERE Pe.Employeeid = Po_Header_Cur.Supplyerid;
      --�������
      --SELECT sum(dt.) FROM Bms_Su_Con_Dtl_Tmp dt where dt.suconid = Po_Header_Cur.Suconid;
      --��ȡ�ֿ�ID
      SELECT MIN(s.Storerid)
        INTO v_Storerid
        FROM Pub_Storer s
       WHERE s.Usestatus = 1
            --AND s.Storerid <> 112
         AND s.Entryid = Po_Header_Cur.Entryid;
      --������ID 
      SELECT MIN(s.Storageid)
        INTO v_Storageid
        FROM Bms_St_Def s
       WHERE s.Entryid = Po_Header_Cur.Entryid
         AND s.Storagetype = 1
         AND s.Phystoreid = v_Storerid
         AND s.Storagename LIKE '%�ϸ��%'
         AND s.Storagename NOT LIKE '%��%';
    
      --ҵ����id
      SELECT Pe.Deptid
        INTO v_Deptid
        FROM Pub_Employee Pe
       WHERE Pe.Employeeid = Po_Header_Cur.Supplyerid;
      --��Ӧ�̵�ַid
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
         1, --��������Ĭ��1(�ƻ�����)
         0, --���ڱ�ʶ Ĭ��Ϊ0
         Po_Header_Cur.Credate, --ǩ������
         v_Signman, --ǩԼ��
         Po_Header_Cur.Credate, --��ʼ����
         Po_Header_Cur.Credate, --��������
         5, --���ʽ Ĭ��5
         0, --prepay Ĭ��0
         0, --����ʽ Ĭ��0(����)
         2, --���ӷ�ʽ Ĭ��2(�ͻ�)
         v_Total, --�ܽ��
         Po_Header_Cur.Dtl_Lines, --ϸ������
         0, --���ID
         1, --����
         Po_Header_Cur.Entryid,
         7, --��Դ����
         Po_Header_Cur.Credate, --��������
         Po_Header_Cur.Inputmanid,
         Po_Header_Cur.Agentid,
         v_Storerid,
         Po_Header_Cur.Credate + 7, --Ԥ�Ƶ���ʱ��
         v_Storageid,
         Po_Header_Cur.Supplyerid,
         v_Deptid,
         v_Addressid, --��Ӧ�̵�ַid
         1, --����״̬Ĭ��1(��ʱ)
         Po_Header_Cur.Zx_Agentid,
         Po_Header_Cur.Zx_Exceptiontype);
    
      FOR Po_Line_Cur IN Po_Dtl_Tmp(Po_Header_Cur.Suconid) LOOP
        --��Ʒ���װid
        SELECT MAX(b.Goodsdtlid)
          INTO v_Goodsdtlid
          FROM Pub_Goods_Detail b
         WHERE b.Goodsid = Po_Line_Cur.Goodsid
           AND b.Usestatus = 1;
        --ʹ�õ�λ,ʹ�õ�λ����
        SELECT MAX(b.Goodsunit), MAX(b.Baseunitqty)
          INTO v_Goodsuseunit, v_Usepacksize
          FROM Pub_Goods_Unit b
         WHERE b.Goodsid = Po_Line_Cur.Goodsid
           AND b.Baseflag = 1;
        --˰��
        /*        SELECT MAX(Pg.Supplytaxrate)
         INTO v_Taxrate
         FROM Pub_Goods Pg
        WHERE Pg.Goodsid = Po_Line_Cur.Goodsid
          AND Pg.Usestatus = 1;*/
        --�۸�˰�ʡ���������
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
      
        --�������,��ͽ���
        SELECT MAX(b.Lastprice), MAX(b.Lowestprice)
          INTO v_Lastprice, v_Lowestprice
          FROM Bms_Goods_Suprice_Ref b
         WHERE Entryid = Po_Header_Cur.Entryid
           AND Goodsid = Po_Line_Cur.Goodsid;
        --�˹�Ӧ���������
        SELECT MAX(b.Lastprice)
          INTO v_Supplylastprice
          FROM Bms_Goods_Suprice_Supply_Ref b
         WHERE Entryid = Po_Header_Cur.Entryid
           AND Supplyid = Po_Header_Cur.Supplyid
           AND Goodsid = Po_Line_Cur.Goodsid;
        --�ɱ����ۼ����
        v_Costprice := v_Unitprice / (1 + v_Taxrate);
        v_Cost      := v_Costprice * Po_Line_Cur.Goodsuseqty;
      
        --���װ����
        SELECT MAX(Round(Po_Line_Cur.Goodsuseqty / Peg.Large_Tranfer_Rate,
                         6))
          INTO v_Zx_Bigpacageqty
          FROM Pub_Entry_Goods Peg
         WHERE Peg.Goodsid = Po_Line_Cur.Goodsid
           AND Peg.Entryid = Po_Header_Cur.Entryid;
      
        --��������
        SELECT MAX(s.Upqty)
          INTO v_Uplimitqty
          FROM Bms_Busi_Dtl s
         WHERE s.Entryid = Po_Header_Cur.Entryid
           AND s.Goodsid = Po_Line_Cur.Goodsid;
        --�������
        SELECT a.Stqty
          INTO v_Stockqty
          FROM Bms_Calc_Busi_Stqty_v a
         WHERE a.Entryid = Po_Header_Cur.Entryid
           AND a.Goodsid = Po_Line_Cur.Goodsid;
        --����������
        SELECT SUM(Sd.Goodsqty)
          INTO v_Lastthreemonthsaqty
          FROM Bms_Sa_Doc Bsd, Bms_Sa_Dtl Sd
         WHERE Bsd.Salesid = Sd.Salesid
           AND Bsd.Credate > Add_Months(SYSDATE, -3)
           AND Bsd.Entryid = Po_Header_Cur.Entryid
           AND Sd.Goodsid = Po_Line_Cur.Goodsid;
        --�վ�����
        v_Avgdayqty := v_Lastthreemonthsaqty / 90;
        --����δ��������
        SELECT SUM(Sd.Goodsqty)
          INTO v_Sanotioqty
          FROM Bms_Sa_Doc Bsd, Bms_Sa_Dtl Sd
         WHERE Bsd.Salesid = Sd.Salesid
           AND Bsd.Entryid = Po_Header_Cur.Entryid
           AND Sd.Goodsid = Po_Line_Cur.Goodsid
           AND Sd.Stioflag IS NULL;
        --��Ʒ��Ʊ������
        SELECT MAX(Peg.Twogoodsattribute)
          INTO v_Twogoodsattribute
          FROM Pub_Entry_Goods Peg
         WHERE Peg.Entryid = Po_Header_Cur.Entryid
           AND Peg.Goodsid = Po_Line_Cur.Goodsid;
        --��Ʒ��Ʊ������
        IF v_Twogoodsattribute = 0 THEN
          v_Zxgoodstype := 1;
        END IF;
        --�ɲɹ�����
        --�ɲɹ�����=��������-�������-15������;��������+�ѿ���δ��������
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
      
        --��������
        /*
        ��������    �����߼��ǣ�
        ����Ʒ��pub_entry_goods.commoditytype in(11,13)ʱ��
        ��������=7����δ���ɹ���������/�վ�������
        ���򣬿�������=��7����δ���ɹ���������+��ʱ��棩/�վ�����
        */
      
        --��Ʒ����
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
           Po_Header_Cur.Supplyerid, --�ɹ�Աid
           v_Deptid, --ҵ����id
           Po_Line_Cur.Goodsid,
           v_Goodsdtlid,
           Po_Line_Cur.Goodsuseqty,
           v_Goodsuseunit, --ʹ�õ�λ
           Po_Line_Cur.Goodsuseqty, --ʹ�õ�λ����
           v_Taxrate,
           v_Unitprice,
           v_Total_Line,
           1, --״̬
           0, --�Ƿ��н���Э��
           v_Lastprice, --�ϴν���
           v_Lowestprice, --��ͽ���
           v_Supplylastprice, --�˹�Ӧ���������
           1, --�и�ģʽ Ĭ��1
           v_Paylimit, --��������
           v_Usepacksize, --ʹ�õ�λ��С
           v_Settletypeid, --���ʽ
           v_Zx_Bigpacageqty, --���װ����
           v_Costprice, --�ɱ�����
           v_Cost, --�ɱ����
           v_Upqty, --�ɲɹ�����
           v_Line_Id, --�ɹ���Ŀ��ϸid
           1, --�ο��и�ģʽ
           v_Paylimit, --�ο���������
           v_Settletypeid, --�ο����ʽ
           v_Uplimitqty, --��������
           v_Avgdayqty, --�վ�����
           v_Stockqty, --�������
           v_Sanotioqty, --����δ��������
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
  ʵʱ��ȡ���ռƻ���15����;����
  ***/
  PROCEDURE Get_Goods_Info_Sp(p_Goods_List IN In_Goods_List,
                              x_Goods_Res  OUT Get_Goods_List) IS
  
    v_Count      NUMBER;
    v_Plan_Qty   NUMBER;
    v_Online_Qty NUMBER;
  BEGIN
  
    FOR i IN 1 .. p_Goods_List.Count LOOP
      --���ռƻ�
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
    
      --15����;����
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

  /*��Ӧ��֤��У��*/
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
                       '","status":"E","error_msg":"Ч��ʧЧ����δ����"}';
            Appmess := Appmess || Get_Str || ',';
          END IF;
          v_Count := v_Count + 1;
        END LOOP;
      END LOOP;
    END LOOP;
    Appmess := '[' || Substr(Appmess, 0, Length(Appmess) - 1) || ']';
  END Po_Plan_Check_License_Sp;
  /*��Ӧ�̷���ί����У��*/
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
                   '","status":"E","error_msg":"��Ӧ�̷���ί����ʧЧ����δά���޶�Ʒ��"}';
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
                     '","status":"E","error_msg":"��Ӧ�̷���ί����ʧЧ����δά���޶�Ʒ��"}';
          Appmess := Appmess || Get_Str || ',';
        END IF;
        EXIT WHEN Agent_Cur%NOTFOUND;
      END LOOP;
      CLOSE Agent_Cur;
      i := i + 1;
    END LOOP;
    Appmess := '[' || Substr(Appmess, 0, Length(Appmess) - 1) || ']';
  END Po_Check_Company_To_Agent_Sp;
  /*�ɹ�Աί����У��*/
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
                   '","status":"E","error_msg":"δά���ɹ�Աί���������ʧЧ"}';
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
                     '","status":"E","error_msg":"δά���ɹ�Աί���������ʧЧ"}';
          Appmess := Appmess || Get_Str || ',';
        END IF;
      
      END LOOP;
      v_Count := v_Count + 1;
    END LOOP;
    Appmess := '[' || Substr(Appmess, 0, Length(Appmess) - 1) || ']';
  END Po_Check_Emp_Proxy_Sp;
  /*�ɹ���ĿУ��*/
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
                   '","status":"E","error_msg":"�ɹ���Ŀδά��"}';
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
                   '","status":"E","error_msg":"�ɹ���Ŀδά��"}';
        Appmess := Appmess || Get_Str || ',';
        /*Get_Str := '{' || '"entryid":"' || v_Entryid || '","entryname":"' ||
                   v_Entryname || '","supplyid":"' || v_Supplyid ||
                   '","supplyname":"' || v_Supplyname || '","agentid":"' ||
                   v_Agentid1 || '","agentname":"' || v_Agentname ||
                   '","goodsid":"' || v_Goodsid || '","goodsname":"' ||
                   v_Goodsname || '","supplyerid":"' || v_Supplyerid ||
                   '","supplyername":"' || v_Supplyername ||
                   '","status":"E","error_msg":"�ɹ���Ŀδά��"}';
        Appmess := Appmess || Get_Str || ',';*/
      END IF;
      --v_Count := v_Count + 1;
    END LOOP;
    Appmess := '[' || Substr(Appmess, 0, Length(Appmess) - 1) || ']';
  END Po_Check_Su_Price_Sp;
  /*�ɹ���Ʊ����У��*/
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
                   '","status":"S","error_msg":"��Ӧ�̷�Ʊ��Ʒδ����"}';
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
                     '","status":"S","error_msg":"��Ӧ�̷�Ʊ��Ʒδ����"}';
          Appmess := Appmess || Get_Str || ',';
        ELSE
          Get_Str := '{' || '"entryid":"' || v_Entryid || '","entryname":"' ||
                     v_Entryname || '","supplyid":"' || v_Supplyid ||
                     '","supplyname":"' || v_Supplyname || '","goodsid":"' ||
                     v_Goodsid || '","goodsname":"' || v_Goodsname ||
                     '","status":"E","error_msg":"�г�60��δ����Ʊ�ɹ���ϸ"}';
          Appmess := Appmess || Get_Str || ',';
        END IF;
      END LOOP;
      v_Count := v_Count + 1;
    END LOOP;
    Appmess := '[' || Substr(Appmess, 0, Length(Appmess) - 1) || ']';
  END Po_Check_Su_Fpcq_Sp;
  /*��Ӧ��֤�ջ�Ʒ��ΧУ��*/
  PROCEDURE Po_Check_Goods_License_Sp(Datajson IN CLOB, Appmess OUT CLOB) IS
    Get_Json     Json;
    Get_Jsonlist Json_List;
  
    v_Licensename  Gsp_License_Type.Licensename%TYPE;
    v_Validenddate DATE;
  
    --��ȡ��Ʒ��Ӫ��Χ������
    CURSOR Check_Goods_Cur(i_Entryid NUMBER, i_Goodsid NUMBER) IS
      SELECT a.Busiscope, a.Medicinetype --��Ӫ��Χ,����
        FROM Pub_Entry_Goods a
       WHERE a.Entryid = i_Entryid
         AND a.Goodsid = i_Goodsid;
  
    --��Ӫ��Χcursor
    CURSOR Busiscope_Cur(i_Entryid NUMBER, i_Supplyid NUMBER) IS
      SELECT c.Licensetypeid, b.Rangectrl, d.Licensename
        FROM Pub_Entry_Supplyer a,
             Gsp_Category_Doc   b, --֤�չܿط��ඨ��
             Gsp_Category_Dtl   c,
             Gsp_License_Type   d --��ҵ֤�����͹���
       WHERE a.Gspcategoryid = b.Categoryid
         AND b.Categoryid = c.Categoryid
         AND c.Licensetypeid = d.Licensetypeid
         AND b.Rangectrl = 1 --���վ�Ӫ��Χά�� 1����Ӫ��Χ
         AND d.Rangeflag = 1 --�Ƿ񺬾�Ӫ��Χ
         AND a.Supplyid = i_Supplyid
         AND a.Entryid = i_Entryid;
    --����cursor
    CURSOR Medicinetype_Cur(i_Entryid NUMBER, i_Supplyid NUMBER) IS
      SELECT c.Licensetypeid, b.Rangectrl, d.Licensename
        FROM Pub_Entry_Supplyer a,
             Gsp_Category_Doc   b,
             Gsp_Category_Dtl   c,
             Gsp_License_Type   d
       WHERE a.Gspcategoryid = b.Categoryid
         AND b.Categoryid = c.Categoryid
         AND c.Licensetypeid = d.Licensetypeid
         AND b.Rangectrl = 2 --��Ӫ��Χ����  2�������
         AND d.Rangeflag = 1 --�Ƿ񺬾�Ӫ��Χ
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
      --���ݻ�Ʒ��Ӫ��Χ��������������֤��
      FOR Cg_Cur IN Check_Goods_Cur(v_Entryid, v_Goodsid) LOOP
      
        --���ȼ�龭Ӫ��Χ
        --��龭Ӫ��Χǰ �ж��Ƿ���ں��о�Ӫ��Χ��֤��ȱʧ��� v_Count = 0 ����ȱʧ��v_Count > 0 ����ȱʧ
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
                     '","status":"E","error_msg":"֤��ȱʧ"}';
          Appmess := Appmess || Get_Str || ',';
          EXIT;
        ELSE
          --��ȡ�α�����
          v_Loop_Count := 0;
          SELECT COUNT(1)
            INTO v_Count
            FROM Pub_Entry_Supplyer a,
                 Gsp_Category_Doc   b, --֤�չܿط��ඨ��
                 Gsp_Category_Dtl   c,
                 Gsp_License_Type   d --��ҵ֤�����͹���
           WHERE a.Gspcategoryid = b.Categoryid
             AND b.Categoryid = c.Categoryid
             AND c.Licensetypeid = d.Licensetypeid
             AND b.Rangectrl = 1 --���վ�Ӫ��Χά�� 1����Ӫ��Χ
             AND d.Rangeflag = 1 --�Ƿ񺬾�Ӫ��Χ
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
                         '","status":"E","error_msg":"��Ӧ��֤��ʧЧ����û��ά����Ӫ��Χ"}';
            
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
                           '","status":"E","error_msg":"��Ӧ��֤����ʧЧ"}';
                Appmess := Appmess || Get_Str || ',';
              END IF;
            END IF;
          END LOOP;
        END IF;
      
        --������ǰ �ж��Ƿ���ں��о�Ӫ��Χ��֤��ȱʧ��� v_Count = 0 ����ȱʧ��v_Count > 0 ����ȱʧ
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
                     '","status":"E","error_msg":"֤��ȱʧ"}';
          Appmess := Appmess || Get_Str || ',';
          EXIT;
        ELSE
          v_Loop_Count := 0;
          --��ȡ�α�����
          SELECT COUNT(1)
            INTO v_Count
            FROM Pub_Entry_Supplyer a,
                 Gsp_Category_Doc   b,
                 Gsp_Category_Dtl   c,
                 Gsp_License_Type   d
           WHERE a.Gspcategoryid = b.Categoryid
             AND b.Categoryid = c.Categoryid
             AND c.Licensetypeid = d.Licensetypeid
             AND b.Rangectrl = 2 --��Ӫ��Χ����  2�������
             AND d.Rangeflag = 1 --�Ƿ񺬾�Ӫ��Χ
             AND a.Supplyid = v_Supplyid
             AND a.Entryid = v_Entryid;
          --��μ����� ����Ʒ�ļ��� �Ƿ��ڹ�Ӧ�̵�֤�ռ��ͷ�Χ��
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
                         '","status":"E","error_msg":"��Ӧ��֤��ʧЧ����û��ά����Ӫ��Χ"}';
            
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
                           '","status":"E","error_msg":"��Ӧ��֤����ʧЧ"}';
                Appmess := Appmess || Get_Str || ',';
              
              END IF;
            END IF;
          END LOOP;
        END IF;
      END LOOP;
    
    END LOOP;
    Appmess := '[' || Substr(Appmess, 0, Length(Appmess) - 1) || ']';
  END Po_Check_Goods_License_Sp;

  /*��ƷУ��*/
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
                   '","status":"E","error_msg":"��Ʒ��Ч"}';
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
  �ɹ�������ʱת�ƻ�
  ***/
  PROCEDURE Po_Tmp_To_Plan_Sp IS
  
    CURSOR Po_Doc_Tmp IS
      SELECT * FROM Bms_Su_Con_Doc_Tmp WHERE Status = 0;
    CURSOR Po_Dtl_Tmp(p_Suconid NUMBER) IS
      SELECT * FROM Bms_Su_Con_Dtl_Tmp s WHERE s.Suconid = p_Suconid;
  
    v_Taxrate             Bms_Su_Plan.Tax_Rate%TYPE; --˰��
    v_Unitprice           Bms_Su_Plan.Unitprice%TYPE; --����
    v_Line_Id             Bms_Su_Plan.Line_Id%TYPE; --�ɹ���Ŀ��ϸid
    v_Paylimit            Bms_Su_Plan.Paylimit%TYPE; --��������
    v_Settletypeid        Bms_Su_Plan.Paymethod%TYPE; --���ʽ
    v_Stockqty            Bms_Su_Plan.Stqty%TYPE; --�������
    v_Upqty               Bms_Su_Plan.Upqty%TYPE; --��������
    v_Downqty             Bms_Su_Plan.Downqty%TYPE; --��������
    v_Paydate_Choice_Code Bms_Su_Plan.Paymethod%TYPE; --�и�ģʽ
    v_Lastthreemonthsaqty Bms_Su_Con_Dtl.Lastthreemonthsaqty%TYPE; --����������
    v_Avgdayqty           Bms_Su_Plan.Avgdayqty%TYPE; --�վ�����
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
      
        --�������
        SELECT MAX(a.Stqty)
          INTO v_Stockqty
          FROM Bms_Calc_Busi_Stqty_v a
         WHERE a.Entryid = Po_Header_Cur.Entryid
           AND a.Goodsid = Po_Line_Cur.Goodsid;
        --��������
        SELECT MAX(s.Upqty)
          INTO v_Upqty
          FROM Bms_Busi_Dtl s
         WHERE s.Entryid = Po_Header_Cur.Entryid
           AND s.Goodsid = Po_Line_Cur.Goodsid;
        --��������
        SELECT MAX(s.Downqty)
          INTO v_Downqty
          FROM Bms_Busi_Dtl s
         WHERE s.Entryid = Po_Header_Cur.Entryid
           AND s.Goodsid = Po_Line_Cur.Goodsid;
      
        --����������
        SELECT SUM(Sd.Goodsqty)
          INTO v_Lastthreemonthsaqty
          FROM Bms_Sa_Doc Bsd, Bms_Sa_Dtl Sd
         WHERE Bsd.Salesid = Sd.Salesid
           AND Bsd.Credate > Add_Months(SYSDATE, -3)
           AND Bsd.Entryid = Po_Header_Cur.Entryid
           AND Sd.Goodsid = Po_Line_Cur.Goodsid;
        --�վ�����
        v_Avgdayqty := v_Lastthreemonthsaqty / 90;
        IF Po_Line_Cur.Unitprice IS NULL THEN
          --�۸�˰�ʡ���������
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
           v_Paydate_Choice_Code, --�и�ģʽ Ĭ��1
           v_Avgdayqty,
           v_Stockqty,
           NULL,
           v_Upqty,
           v_Downqty,
           v_Settletypeid, --���ʽ Ĭ��5,
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
