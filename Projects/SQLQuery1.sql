SET NOCOUNT ON
GO
DECLARE @hdoc int
DECLARE @doc xml
	,@PlanOutput nVarChar(max)
	,@PrintOutput bit
	,@SelectOutput bit
SET @doc ='
<ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="1.0" Build="9.00.4035.00">
  <BatchSequence>
    <Batch>
      <Statements>
        <StmtSimple StatementText="(@iRecordCount int OUTPUT)declare @t TABLE (ID int IDENTITY PRIMARY KEY, iCompanyID int) INSERT INTO @t(iCompanyID) &#xD;&#xA;		SELECT distinct c.iCompanyID FROM COMPANY c WHERE (c.vchCompanyName LIKE N''Insight-i%'')  AND c.iTypeId IN (900,901,906) UNION SELECT DISTINCT CompanyId FROM Company_Culture WHERE CompanyName1 LIKE N''Insight-i%'' " StatementId="1" StatementCompId="2" StatementType="INSERT" StatementSubTreeCost="0.280451" StatementEstRows="1.5" StatementOptmLevel="FULL" StatementOptmEarlyAbortReason="GoodEnoughPlanFound">
          <QueryPlan CachedPlanSize="48" CompileTime="10" CompileCPU="10" CompileMemory="992">
            <MissingIndexes>
              <MissingIndexGroup Impact="78.0945">
                <MissingIndex Database="[WCDS]" Schema="[dbo]" Table="[Company_Culture]">
                  <ColumnGroup Usage="INEQUALITY">
                    <Column Name="[CompanyName1]" ColumnId="2" />
                  </ColumnGroup>
                  <ColumnGroup Usage="INCLUDE">
                    <Column Name="[CompanyId]" ColumnId="1" />
                  </ColumnGroup>
                </MissingIndex>
              </MissingIndexGroup>
            </MissingIndexes>
            <RelOp NodeId="0" PhysicalOp="Clustered Index Insert" LogicalOp="Insert" EstimateRows="1.5" EstimateIO="0.01" EstimateCPU="1.5e-006" AvgRowSize="9" EstimatedTotalSubtreeCost="0.280451" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
              <OutputList />
              <Update>
                <Object Table="[@t]" Index="[PK__#3A31EDBA__3B2611F3]" />
                <SetPredicate>
                  <ScalarOperator ScalarString="[iCompanyID] = [Union1009],[ID] = [Expr1010]">
                    <ScalarExpressionList>
                      <ScalarOperator>
                        <MultipleAssign>
                          <Assign>
                            <ColumnReference Column="iCompanyID" />
                            <ScalarOperator>
                              <Identifier>
                                <ColumnReference Column="Union1009" />
                              </Identifier>
                            </ScalarOperator>
                          </Assign>
                          <Assign>
                            <ColumnReference Column="ID" />
                            <ScalarOperator>
                              <Identifier>
                                <ColumnReference Column="Expr1010" />
                              </Identifier>
                            </ScalarOperator>
                          </Assign>
                        </MultipleAssign>
                      </ScalarOperator>
                    </ScalarExpressionList>
                  </ScalarOperator>
                </SetPredicate>
                <RelOp NodeId="1" PhysicalOp="Compute Scalar" LogicalOp="Compute Scalar" EstimateRows="1.5" EstimateIO="0" EstimateCPU="1.5e-007" AvgRowSize="15" EstimatedTotalSubtreeCost="0.270449" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
                  <OutputList>
                    <ColumnReference Column="Union1009" />
                    <ColumnReference Column="Expr1010" />
                  </OutputList>
                  <ComputeScalar>
                    <DefinedValues>
                      <DefinedValue>
                        <ColumnReference Column="Expr1010" />
                        <ScalarOperator ScalarString="getidentity((976350650),(2),N''@t'')">
                          <Intrinsic FunctionName="getidentity">
                            <ScalarOperator>
                              <Const ConstValue="(976350650)" />
                            </ScalarOperator>
                            <ScalarOperator>
                              <Const ConstValue="(2)" />
                            </ScalarOperator>
                            <ScalarOperator>
                              <Const ConstValue="N''@t''" />
                            </ScalarOperator>
                          </Intrinsic>
                        </ScalarOperator>
                      </DefinedValue>
                    </DefinedValues>
                    <RelOp NodeId="2" PhysicalOp="Top" LogicalOp="Top" EstimateRows="1.5" EstimateIO="0" EstimateCPU="1.5e-007" AvgRowSize="11" EstimatedTotalSubtreeCost="0.270449" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
                      <OutputList>
                        <ColumnReference Column="Union1009" />
                      </OutputList>
                      <Top RowCount="1" IsPercent="0" WithTies="0">
                        <TopExpression>
                          <ScalarOperator ScalarString="(0)">
                            <Const ConstValue="(0)" />
                          </ScalarOperator>
                        </TopExpression>
                        <RelOp NodeId="3" PhysicalOp="Sort" LogicalOp="Distinct Sort" EstimateRows="1.5" EstimateIO="0.0112613" EstimateCPU="0.000103131" AvgRowSize="11" EstimatedTotalSubtreeCost="0.270449" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
                          <OutputList>
                            <ColumnReference Column="Union1009" />
                          </OutputList>
                          <MemoryFractions Input="0.5" Output="1" />
                          <Sort Distinct="1">
                            <OrderBy>
                              <OrderByColumn Ascending="1">
                                <ColumnReference Column="Union1009" />
                              </OrderByColumn>
                            </OrderBy>
                            <RelOp NodeId="4" PhysicalOp="Concatenation" LogicalOp="Concatenation" EstimateRows="2" EstimateIO="0" EstimateCPU="2e-007" AvgRowSize="11" EstimatedTotalSubtreeCost="0.259085" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
                              <OutputList>
                                <ColumnReference Column="Union1009" />
                              </OutputList>
                              <Concat>
                                <DefinedValues>
                                  <DefinedValue>
                                    <ColumnReference Column="Union1009" />
                                    <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iCompanyID" />
                                    <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company_Culture]" Column="CompanyId" />
                                  </DefinedValue>
                                </DefinedValues>
                                <RelOp NodeId="5" PhysicalOp="Filter" LogicalOp="Filter" EstimateRows="1" EstimateIO="0" EstimateCPU="1.18e-006" AvgRowSize="11" EstimatedTotalSubtreeCost="0.00657244" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
                                  <OutputList>
                                    <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iCompanyID" />
                                  </OutputList>
                                  <Filter StartupExpression="0">
                                    <RelOp NodeId="6" PhysicalOp="Nested Loops" LogicalOp="Inner Join" EstimateRows="1" EstimateIO="0" EstimateCPU="4.18e-006" AvgRowSize="15" EstimatedTotalSubtreeCost="0.00657126" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
                                      <OutputList>
                                        <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iCompanyID" />
                                        <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iTypeID" />
                                      </OutputList>
                                      <NestedLoops Optimized="1">
                                        <OuterReferences>
                                          <ColumnReference Column="Uniq1005" />
                                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyCN" />
                                        </OuterReferences>
                                        <RelOp NodeId="8" PhysicalOp="Index Seek" LogicalOp="Index Seek" EstimateRows="1" EstimateIO="0.003125" EstimateCPU="0.0001581" AvgRowSize="112" EstimatedTotalSubtreeCost="0.0032831" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
                                          <OutputList>
                                            <ColumnReference Column="Uniq1005" />
                                            <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyName" />
                                            <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyCN" />
                                          </OutputList>
                                          <IndexScan Ordered="1" ScanDirection="FORWARD" ForcedIndex="0" NoExpandHint="0">
                                            <DefinedValues>
                                              <DefinedValue>
                                                <ColumnReference Column="Uniq1005" />
                                              </DefinedValue>
                                              <DefinedValue>
                                                <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyName" />
                                              </DefinedValue>
                                              <DefinedValue>
                                                <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyCN" />
                                              </DefinedValue>
                                            </DefinedValues>
                                            <Object Database="[WCDS]" Schema="[dbo]" Table="[Company]" Index="[CompanyName_ndx]" Alias="[c]" />
                                            <SeekPredicates>
                                              <SeekPredicate>
                                                <StartRange ScanType="GE">
                                                  <RangeColumns>
                                                    <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyName" />
                                                  </RangeColumns>
                                                  <RangeExpressions>
                                                    <ScalarOperator ScalarString="N''Insight-i''">
                                                      <Const ConstValue="N''Insight-i''" />
                                                    </ScalarOperator>
                                                  </RangeExpressions>
                                                </StartRange>
                                                <EndRange ScanType="LT">
                                                  <RangeColumns>
                                                    <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyName" />
                                                  </RangeColumns>
                                                  <RangeExpressions>
                                                    <ScalarOperator ScalarString="N''Insight-J''">
                                                      <Const ConstValue="N''Insight-J''" />
                                                    </ScalarOperator>
                                                  </RangeExpressions>
                                                </EndRange>
                                              </SeekPredicate>
                                            </SeekPredicates>
                                            <Predicate>
                                              <ScalarOperator ScalarString="[WCDS].[dbo].[Company].[vchCompanyName] as [c].[vchCompanyName] like N''Insight-i%''">
                                                <Intrinsic FunctionName="like">
                                                  <ScalarOperator>
                                                    <Identifier>
                                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyName" />
                                                    </Identifier>
                                                  </ScalarOperator>
                                                  <ScalarOperator>
                                                    <Const ConstValue="N''Insight-i%''" />
                                                  </ScalarOperator>
                                                </Intrinsic>
                                              </ScalarOperator>
                                            </Predicate>
                                          </IndexScan>
                                        </RelOp>
                                        <RelOp NodeId="10" PhysicalOp="Clustered Index Seek" LogicalOp="Clustered Index Seek" EstimateRows="1" EstimateIO="0.003125" EstimateCPU="0.0001581" AvgRowSize="15" EstimatedTotalSubtreeCost="0.0032831" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
                                          <OutputList>
                                            <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iCompanyID" />
                                            <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iTypeID" />
                                          </OutputList>
                                          <IndexScan Lookup="1" Ordered="1" ScanDirection="FORWARD" ForcedIndex="0" NoExpandHint="0">
                                            <DefinedValues>
                                              <DefinedValue>
                                                <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iCompanyID" />
                                              </DefinedValue>
                                              <DefinedValue>
                                                <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iTypeID" />
                                              </DefinedValue>
                                            </DefinedValues>
                                            <Object Database="[WCDS]" Schema="[dbo]" Table="[Company]" Index="[CompanyCn_clndx]" Alias="[c]" TableReferenceId="-1" />
                                            <SeekPredicates>
                                              <SeekPredicate>
                                                <Prefix ScanType="EQ">
                                                  <RangeColumns>
                                                    <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyCN" />
                                                    <ColumnReference Column="Uniq1005" />
                                                  </RangeColumns>
                                                  <RangeExpressions>
                                                    <ScalarOperator ScalarString="[WCDS].[dbo].[Company].[vchCompanyCN] as [c].[vchCompanyCN]">
                                                      <Identifier>
                                                        <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyCN" />
                                                      </Identifier>
                                                    </ScalarOperator>
                                                    <ScalarOperator ScalarString="[Uniq1005]">
                                                      <Identifier>
                                                        <ColumnReference Column="Uniq1005" />
                                                      </Identifier>
                                                    </ScalarOperator>
                                                  </RangeExpressions>
                                                </Prefix>
                                              </SeekPredicate>
                                            </SeekPredicates>
                                          </IndexScan>
                                        </RelOp>
                                      </NestedLoops>
                                    </RelOp>
                                    <Predicate>
                                      <ScalarOperator ScalarString="[WCDS].[dbo].[Company].[iTypeID] as [c].[iTypeID]=(900) OR [WCDS].[dbo].[Company].[iTypeID] as [c].[iTypeID]=(901) OR [WCDS].[dbo].[Company].[iTypeID] as [c].[iTypeID]=(906)">
                                        <Logical Operation="OR">
                                          <ScalarOperator>
                                            <Compare CompareOp="EQ">
                                              <ScalarOperator>
                                                <Identifier>
                                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iTypeID" />
                                                </Identifier>
                                              </ScalarOperator>
                                              <ScalarOperator>
                                                <Const ConstValue="(900)" />
                                              </ScalarOperator>
                                            </Compare>
                                          </ScalarOperator>
                                          <ScalarOperator>
                                            <Compare CompareOp="EQ">
                                              <ScalarOperator>
                                                <Identifier>
                                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iTypeID" />
                                                </Identifier>
                                              </ScalarOperator>
                                              <ScalarOperator>
                                                <Const ConstValue="(901)" />
                                              </ScalarOperator>
                                            </Compare>
                                          </ScalarOperator>
                                          <ScalarOperator>
                                            <Compare CompareOp="EQ">
                                              <ScalarOperator>
                                                <Identifier>
                                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iTypeID" />
                                                </Identifier>
                                              </ScalarOperator>
                                              <ScalarOperator>
                                                <Const ConstValue="(906)" />
                                              </ScalarOperator>
                                            </Compare>
                                          </ScalarOperator>
                                        </Logical>
                                      </ScalarOperator>
                                    </Predicate>
                                  </Filter>
                                </RelOp>
                                <RelOp NodeId="17" PhysicalOp="Clustered Index Scan" LogicalOp="Clustered Index Scan" EstimateRows="1" EstimateIO="0.200903" EstimateCPU="0.0287416" AvgRowSize="32" EstimatedTotalSubtreeCost="0.229644" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
                                  <OutputList>
                                    <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company_Culture]" Column="CompanyId" />
                                  </OutputList>
                                  <IndexScan Ordered="0" ForcedIndex="0" NoExpandHint="0">
                                    <DefinedValues>
                                      <DefinedValue>
                                        <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company_Culture]" Column="CompanyId" />
                                      </DefinedValue>
                                    </DefinedValues>
                                    <Object Database="[WCDS]" Schema="[dbo]" Table="[Company_Culture]" Index="[Company_Culture_PK]" />
                                    <Predicate>
                                      <ScalarOperator ScalarString="[WCDS].[dbo].[Company_Culture].[CompanyName1] like N''Insight-i%''">
                                        <Intrinsic FunctionName="like">
                                          <ScalarOperator>
                                            <Identifier>
                                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company_Culture]" Column="CompanyName1" />
                                            </Identifier>
                                          </ScalarOperator>
                                          <ScalarOperator>
                                            <Const ConstValue="N''Insight-i%''" />
                                          </ScalarOperator>
                                        </Intrinsic>
                                      </ScalarOperator>
                                    </Predicate>
                                  </IndexScan>
                                </RelOp>
                              </Concat>
                            </RelOp>
                          </Sort>
                        </RelOp>
                      </Top>
                    </RelOp>
                  </ComputeScalar>
                </RelOp>
              </Update>
            </RelOp>
          </QueryPlan>
        </StmtSimple>
        <StmtSimple StatementText=" SET @iRecordCount = @@ROWCOUNT" StatementId="2" StatementCompId="3" StatementType="ASSIGN" />
        <StmtCond StatementText=" IF @iRecordCount BETWEEN 1 AND 2000 &#xD;&#xA;" StatementId="3" StatementCompId="4" StatementType="COND">
          <Condition />
          <Then>
            <Statements>
              <StmtSimple StatementText="	SELECT DISTINCT c.iCompanyID, &#xD;&#xA;		vchCompanyCN = c.vchCompanyCN, &#xD;&#xA;		vchCompanyName = c.vchCompanyname, &#xD;&#xA;		vchContactName = cn.vchName,&#xD;&#xA;		vchTermsCode = c.vchTermsCode, &#xD;&#xA;		dtCreated = c.dtCreated, &#xD;&#xA;		dtModified = c.dtModified, &#xD;&#xA;		iPricePlanTypeID = c.iPricePlanTypeID, &#xD;&#xA;		iOriginalSystemID = c.iOriginalSystemID,&#xD;&#xA;		vchBillToCity = a.vchCity,&#xD;&#xA;		CASE a.nchCountryCode&#xD;&#xA;			WHEN ''USA'' THEN a.chStateCode&#xD;&#xA;			WHEN ''JPN'' THEN a.chStateCode&#xD;&#xA;			WHEN ''CAN'' THEN COALESCE(a.vchProvince, a.chStateCode)&#xD;&#xA;			ELSE NULL&#xD;&#xA;		END AS chBillToStateCode,&#xD;&#xA;		nchBillToCountryCode = a.nchCountryCode,&#xD;&#xA;        tiGINSEnabledFlag = 0,&#xD;&#xA;        tiNBAEnabledFlag = 0,&#xD;&#xA;		CASE ParentCompanyID &#xD;&#xA;			WHEN c.iCompanyID THEN 1&#xD;&#xA;			ELSE 0 END AS IsParentCompany&#xD;&#xA;	FROM @t t&#xD;&#xA;	JOIN COMPANY c  on t.iCompanyID = c.iCompanyID&#xD;&#xA;	LEFT OUTER JOIN (SELECT * FROM CONTACT WHERE iTYpeID = 304) cn &#xD;&#xA;		on c.iCompanyID = cn.iCompanyID&#xD;&#xA;	LEFT OUTER JOIN Address a&#xD;&#xA;		on c.iPrimBillToAddressID = a.iAddressID&#xD;&#xA;	WHERE t.ID BETWEEN 1 AND &#xD;&#xA;				1000" StatementId="4" StatementCompId="5" StatementType="SELECT" StatementSubTreeCost="0.0310819" StatementEstRows="1" StatementOptmLevel="FULL" StatementOptmEarlyAbortReason="GoodEnoughPlanFound">
                <QueryPlan CachedPlanSize="105" CompileTime="16" CompileCPU="16" CompileMemory="1088">
                  <RelOp NodeId="1" PhysicalOp="Sort" LogicalOp="Distinct Sort" EstimateRows="1" EstimateIO="0.0112613" EstimateCPU="0.000100586" AvgRowSize="586" EstimatedTotalSubtreeCost="0.0310819" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
                    <OutputList>
                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iCompanyID" />
                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iOriginalSystemID" />
                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyName" />
                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyCN" />
                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchTermsCode" />
                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iPricePlanTypeID" />
                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="dtCreated" />
                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="dtModified" />
                      <ColumnReference Column="Expr1009" />
                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="vchCity" />
                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="nchCountryCode" />
                      <ColumnReference Column="Expr1013" />
                      <ColumnReference Column="Expr1014" />
                      <ColumnReference Column="Expr1016" />
                    </OutputList>
                    <MemoryFractions Input="0.25" Output="1" />
                    <Sort Distinct="1">
                      <OrderBy>
                        <OrderByColumn Ascending="1">
                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iCompanyID" />
                        </OrderByColumn>
                        <OrderByColumn Ascending="1">
                          <ColumnReference Column="Expr1009" />
                        </OrderByColumn>
                        <OrderByColumn Ascending="1">
                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="vchCity" />
                        </OrderByColumn>
                        <OrderByColumn Ascending="1">
                          <ColumnReference Column="Expr1013" />
                        </OrderByColumn>
                        <OrderByColumn Ascending="1">
                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="nchCountryCode" />
                        </OrderByColumn>
                        <OrderByColumn Ascending="1">
                          <ColumnReference Column="Expr1016" />
                        </OrderByColumn>
                      </OrderBy>
                      <RelOp NodeId="2" PhysicalOp="Compute Scalar" LogicalOp="Compute Scalar" EstimateRows="1" EstimateIO="0" EstimateCPU="1e-007" AvgRowSize="590" EstimatedTotalSubtreeCost="0.0197201" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
                        <OutputList>
                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iCompanyID" />
                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iOriginalSystemID" />
                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyName" />
                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyCN" />
                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchTermsCode" />
                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iPricePlanTypeID" />
                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="dtCreated" />
                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="dtModified" />
                          <ColumnReference Column="Expr1009" />
                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="vchCity" />
                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="nchCountryCode" />
                          <ColumnReference Column="Expr1013" />
                          <ColumnReference Column="Expr1014" />
                          <ColumnReference Column="Expr1015" />
                          <ColumnReference Column="Expr1016" />
                        </OutputList>
                        <ComputeScalar>
                          <DefinedValues>
                            <DefinedValue>
                              <ColumnReference Column="Expr1013" />
                              <ScalarOperator ScalarString="CASE WHEN [WCDS].[dbo].[Address].[nchCountryCode] as [a].[nchCountryCode]=N''USA'' THEN [WCDS].[dbo].[Address].[chStateCode] as [a].[chStateCode] ELSE CASE WHEN [WCDS].[dbo].[Address].[nchCountryCode] as [a].[nchCountryCode]=N''JPN'' THEN [WCDS].[dbo].[Address].[chStateCode] as [a].[chStateCode] ELSE CASE WHEN [WCDS].[dbo].[Address].[nchCountryCode] as [a].[nchCountryCode]=N''CAN'' THEN CASE WHEN [WCDS].[dbo].[Address].[vchProvince] as [a].[vchProvince] IS NOT NULL THEN [WCDS].[dbo].[Address].[vchProvince] as [a].[vchProvince] ELSE [WCDS].[dbo].[Address].[chStateCode] as [a].[chStateCode] END ELSE NULL END END END">
                                <IF>
                                  <Condition>
                                    <ScalarOperator>
                                      <Compare CompareOp="EQ">
                                        <ScalarOperator>
                                          <Identifier>
                                            <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="nchCountryCode" />
                                          </Identifier>
                                        </ScalarOperator>
                                        <ScalarOperator>
                                          <Const ConstValue="N''USA''" />
                                        </ScalarOperator>
                                      </Compare>
                                    </ScalarOperator>
                                  </Condition>
                                  <Then>
                                    <ScalarOperator>
                                      <Identifier>
                                        <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="chStateCode" />
                                      </Identifier>
                                    </ScalarOperator>
                                  </Then>
                                  <Else>
                                    <ScalarOperator>
                                      <IF>
                                        <Condition>
                                          <ScalarOperator>
                                            <Compare CompareOp="EQ">
                                              <ScalarOperator>
                                                <Identifier>
                                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="nchCountryCode" />
                                                </Identifier>
                                              </ScalarOperator>
                                              <ScalarOperator>
                                                <Const ConstValue="N''JPN''" />
                                              </ScalarOperator>
                                            </Compare>
                                          </ScalarOperator>
                                        </Condition>
                                        <Then>
                                          <ScalarOperator>
                                            <Identifier>
                                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="chStateCode" />
                                            </Identifier>
                                          </ScalarOperator>
                                        </Then>
                                        <Else>
                                          <ScalarOperator>
                                            <IF>
                                              <Condition>
                                                <ScalarOperator>
                                                  <Compare CompareOp="EQ">
                                                    <ScalarOperator>
                                                      <Identifier>
                                                        <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="nchCountryCode" />
                                                      </Identifier>
                                                    </ScalarOperator>
                                                    <ScalarOperator>
                                                      <Const ConstValue="N''CAN''" />
                                                    </ScalarOperator>
                                                  </Compare>
                                                </ScalarOperator>
                                              </Condition>
                                              <Then>
                                                <ScalarOperator>
                                                  <IF>
                                                    <Condition>
                                                      <ScalarOperator>
                                                        <Compare CompareOp="IS NOT">
                                                          <ScalarOperator>
                                                            <Identifier>
                                                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="vchProvince" />
                                                            </Identifier>
                                                          </ScalarOperator>
                                                          <ScalarOperator>
                                                            <Const ConstValue="NULL" />
                                                          </ScalarOperator>
                                                        </Compare>
                                                      </ScalarOperator>
                                                    </Condition>
                                                    <Then>
                                                      <ScalarOperator>
                                                        <Identifier>
                                                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="vchProvince" />
                                                        </Identifier>
                                                      </ScalarOperator>
                                                    </Then>
                                                    <Else>
                                                      <ScalarOperator>
                                                        <Identifier>
                                                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="chStateCode" />
                                                        </Identifier>
                                                      </ScalarOperator>
                                                    </Else>
                                                  </IF>
                                                </ScalarOperator>
                                              </Then>
                                              <Else>
                                                <ScalarOperator>
                                                  <Const ConstValue="NULL" />
                                                </ScalarOperator>
                                              </Else>
                                            </IF>
                                          </ScalarOperator>
                                        </Else>
                                      </IF>
                                    </ScalarOperator>
                                  </Else>
                                </IF>
                              </ScalarOperator>
                            </DefinedValue>
                            <DefinedValue>
                              <ColumnReference Column="Expr1014" />
                              <ScalarOperator ScalarString="(0)">
                                <Const ConstValue="(0)" />
                              </ScalarOperator>
                            </DefinedValue>
                            <DefinedValue>
                              <ColumnReference Column="Expr1015" />
                              <ScalarOperator ScalarString="(0)">
                                <Const ConstValue="(0)" />
                              </ScalarOperator>
                            </DefinedValue>
                          </DefinedValues>
                          <RelOp NodeId="3" PhysicalOp="Nested Loops" LogicalOp="Inner Join" EstimateRows="1" EstimateIO="0" EstimateCPU="4.18e-006" AvgRowSize="531" EstimatedTotalSubtreeCost="0.01972" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
                            <OutputList>
                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iCompanyID" />
                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iOriginalSystemID" />
                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyName" />
                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyCN" />
                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchTermsCode" />
                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iPricePlanTypeID" />
                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="dtCreated" />
                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="dtModified" />
                              <ColumnReference Column="Expr1009" />
                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="vchCity" />
                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="chStateCode" />
                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="vchProvince" />
                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="nchCountryCode" />
                              <ColumnReference Column="Expr1016" />
                            </OutputList>
                            <NestedLoops Optimized="0">
                              <PassThru>
                                <ScalarOperator ScalarString="[IsBaseRow1011] IS NULL">
                                  <Compare CompareOp="IS">
                                    <ScalarOperator>
                                      <Identifier>
                                        <ColumnReference Column="IsBaseRow1011" />
                                      </Identifier>
                                    </ScalarOperator>
                                    <ScalarOperator>
                                      <Const ConstValue="NULL" />
                                    </ScalarOperator>
                                  </Compare>
                                </ScalarOperator>
                              </PassThru>
                              <OuterReferences>
                                <ColumnReference Column="Uniq1012" />
                                <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="iEntityID" />
                                <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="iEntityTypeID" />
                              </OuterReferences>
                              <RelOp NodeId="4" PhysicalOp="Nested Loops" LogicalOp="Left Outer Join" EstimateRows="1" EstimateIO="0" EstimateCPU="4.18e-006" AvgRowSize="507" EstimatedTotalSubtreeCost="0.0164324" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
                                <OutputList>
                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iCompanyID" />
                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iOriginalSystemID" />
                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyName" />
                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyCN" />
                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchTermsCode" />
                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iPricePlanTypeID" />
                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="dtCreated" />
                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="dtModified" />
                                  <ColumnReference Column="Expr1009" />
                                  <ColumnReference Column="IsBaseRow1011" />
                                  <ColumnReference Column="Uniq1012" />
                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="iEntityID" />
                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="iEntityTypeID" />
                                  <ColumnReference Column="Expr1016" />
                                </OutputList>
                                <NestedLoops Optimized="1">
                                  <OuterReferences>
                                    <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iPrimBillToAddressID" />
                                  </OuterReferences>
                                  <RelOp NodeId="6" PhysicalOp="Nested Loops" LogicalOp="Left Outer Join" EstimateRows="1" EstimateIO="0" EstimateCPU="4.18e-006" AvgRowSize="498" EstimatedTotalSubtreeCost="0.0131451" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
                                    <OutputList>
                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iCompanyID" />
                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iOriginalSystemID" />
                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyName" />
                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyCN" />
                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchTermsCode" />
                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iPrimBillToAddressID" />
                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iPricePlanTypeID" />
                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="dtCreated" />
                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="dtModified" />
                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Contact]" Column="vchName" />
                                      <ColumnReference Column="Expr1016" />
                                    </OutputList>
                                    <NestedLoops Optimized="0">
                                      <OuterReferences>
                                        <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iCompanyID" />
                                      </OuterReferences>
                                      <RelOp NodeId="7" PhysicalOp="Compute Scalar" LogicalOp="Compute Scalar" EstimateRows="1" EstimateIO="0" EstimateCPU="1e-007" AvgRowSize="241" EstimatedTotalSubtreeCost="0.00985776" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
                                        <OutputList>
                                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iCompanyID" />
                                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iOriginalSystemID" />
                                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyName" />
                                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyCN" />
                                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchTermsCode" />
                                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iPrimBillToAddressID" />
                                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iPricePlanTypeID" />
                                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="dtCreated" />
                                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="dtModified" />
                                          <ColumnReference Column="Expr1016" />
                                        </OutputList>
                                        <ComputeScalar>
                                          <DefinedValues>
                                            <DefinedValue>
                                              <ColumnReference Column="Expr1016" />
                                              <ScalarOperator ScalarString="CASE WHEN [WCDS].[dbo].[Company].[ParentCompanyID] as [c].[ParentCompanyID]=[WCDS].[dbo].[Company].[iCompanyID] as [c].[iCompanyID] THEN (1) ELSE (0) END">
                                                <IF>
                                                  <Condition>
                                                    <ScalarOperator>
                                                      <Compare CompareOp="EQ">
                                                        <ScalarOperator>
                                                          <Identifier>
                                                            <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="ParentCompanyID" />
                                                          </Identifier>
                                                        </ScalarOperator>
                                                        <ScalarOperator>
                                                          <Identifier>
                                                            <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iCompanyID" />
                                                          </Identifier>
                                                        </ScalarOperator>
                                                      </Compare>
                                                    </ScalarOperator>
                                                  </Condition>
                                                  <Then>
                                                    <ScalarOperator>
                                                      <Const ConstValue="(1)" />
                                                    </ScalarOperator>
                                                  </Then>
                                                  <Else>
                                                    <ScalarOperator>
                                                      <Const ConstValue="(0)" />
                                                    </ScalarOperator>
                                                  </Else>
                                                </IF>
                                              </ScalarOperator>
                                            </DefinedValue>
                                          </DefinedValues>
                                          <RelOp NodeId="8" PhysicalOp="Nested Loops" LogicalOp="Inner Join" EstimateRows="1" EstimateIO="0" EstimateCPU="4.18e-006" AvgRowSize="241" EstimatedTotalSubtreeCost="0.00985766" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
                                            <OutputList>
                                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iCompanyID" />
                                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iOriginalSystemID" />
                                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyName" />
                                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyCN" />
                                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchTermsCode" />
                                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iPrimBillToAddressID" />
                                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iPricePlanTypeID" />
                                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="dtCreated" />
                                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="dtModified" />
                                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="ParentCompanyID" />
                                            </OutputList>
                                            <NestedLoops Optimized="1">
                                              <OuterReferences>
                                                <ColumnReference Column="Uniq1004" />
                                                <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyCN" />
                                              </OuterReferences>
                                              <RelOp NodeId="10" PhysicalOp="Nested Loops" LogicalOp="Inner Join" EstimateRows="1" EstimateIO="0" EstimateCPU="4.18e-006" AvgRowSize="78" EstimatedTotalSubtreeCost="0.00657038" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
                                                <OutputList>
                                                  <ColumnReference Column="Uniq1004" />
                                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iCompanyID" />
                                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyCN" />
                                                </OutputList>
                                                <NestedLoops Optimized="1">
                                                  <OuterReferences>
                                                    <ColumnReference Table="@t" Alias="[t]" Column="iCompanyID" />
                                                  </OuterReferences>
                                                  <RelOp NodeId="12" PhysicalOp="Clustered Index Seek" LogicalOp="Clustered Index Seek" EstimateRows="1" EstimateIO="0.003125" EstimateCPU="0.0001581" AvgRowSize="11" EstimatedTotalSubtreeCost="0.0032831" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
                                                    <OutputList>
                                                      <ColumnReference Table="@t" Alias="[t]" Column="iCompanyID" />
                                                    </OutputList>
                                                    <IndexScan Ordered="1" ScanDirection="FORWARD" ForcedIndex="0" NoExpandHint="0">
                                                      <DefinedValues>
                                                        <DefinedValue>
                                                          <ColumnReference Table="@t" Alias="[t]" Column="iCompanyID" />
                                                        </DefinedValue>
                                                      </DefinedValues>
                                                      <Object Table="[@t]" Index="[PK__#3A31EDBA__3B2611F3]" Alias="[t]" />
                                                      <SeekPredicates>
                                                        <SeekPredicate>
                                                          <StartRange ScanType="GE">
                                                            <RangeColumns>
                                                              <ColumnReference Table="@t" Alias="[t]" Column="ID" />
                                                            </RangeColumns>
                                                            <RangeExpressions>
                                                              <ScalarOperator ScalarString="(1)">
                                                                <Const ConstValue="(1)" />
                                                              </ScalarOperator>
                                                            </RangeExpressions>
                                                          </StartRange>
                                                          <EndRange ScanType="LE">
                                                            <RangeColumns>
                                                              <ColumnReference Table="@t" Alias="[t]" Column="ID" />
                                                            </RangeColumns>
                                                            <RangeExpressions>
                                                              <ScalarOperator ScalarString="(10000)">
                                                                <Const ConstValue="(10000)" />
                                                              </ScalarOperator>
                                                            </RangeExpressions>
                                                          </EndRange>
                                                        </SeekPredicate>
                                                      </SeekPredicates>
                                                    </IndexScan>
                                                  </RelOp>
                                                  <RelOp NodeId="13" PhysicalOp="Index Seek" LogicalOp="Index Seek" EstimateRows="1" EstimateIO="0.003125" EstimateCPU="0.0001581" AvgRowSize="74" EstimatedTotalSubtreeCost="0.0032831" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
                                                    <OutputList>
                                                      <ColumnReference Column="Uniq1004" />
                                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iCompanyID" />
                                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyCN" />
                                                    </OutputList>
                                                    <IndexScan Ordered="1" ScanDirection="FORWARD" ForcedIndex="0" NoExpandHint="0">
                                                      <DefinedValues>
                                                        <DefinedValue>
                                                          <ColumnReference Column="Uniq1004" />
                                                        </DefinedValue>
                                                        <DefinedValue>
                                                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iCompanyID" />
                                                        </DefinedValue>
                                                        <DefinedValue>
                                                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyCN" />
                                                        </DefinedValue>
                                                      </DefinedValues>
                                                      <Object Database="[WCDS]" Schema="[dbo]" Table="[Company]" Index="[Company_pk_ndx]" Alias="[c]" />
                                                      <SeekPredicates>
                                                        <SeekPredicate>
                                                          <Prefix ScanType="EQ">
                                                            <RangeColumns>
                                                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iCompanyID" />
                                                            </RangeColumns>
                                                            <RangeExpressions>
                                                              <ScalarOperator ScalarString="@t.[iCompanyID] as [t].[iCompanyID]">
                                                                <Identifier>
                                                                  <ColumnReference Table="@t" Alias="[t]" Column="iCompanyID" />
                                                                </Identifier>
                                                              </ScalarOperator>
                                                            </RangeExpressions>
                                                          </Prefix>
                                                        </SeekPredicate>
                                                      </SeekPredicates>
                                                    </IndexScan>
                                                  </RelOp>
                                                </NestedLoops>
                                              </RelOp>
                                              <RelOp NodeId="15" PhysicalOp="Clustered Index Seek" LogicalOp="Clustered Index Seek" EstimateRows="1" EstimateIO="0.003125" EstimateCPU="0.0001581" AvgRowSize="175" EstimatedTotalSubtreeCost="0.0032831" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
                                                <OutputList>
                                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iOriginalSystemID" />
                                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyName" />
                                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchTermsCode" />
                                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iPrimBillToAddressID" />
                                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iPricePlanTypeID" />
                                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="dtCreated" />
                                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="dtModified" />
                                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="ParentCompanyID" />
                                                </OutputList>
                                                <IndexScan Lookup="1" Ordered="1" ScanDirection="FORWARD" ForcedIndex="0" NoExpandHint="0">
                                                  <DefinedValues>
                                                    <DefinedValue>
                                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iOriginalSystemID" />
                                                    </DefinedValue>
                                                    <DefinedValue>
                                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyName" />
                                                    </DefinedValue>
                                                    <DefinedValue>
                                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchTermsCode" />
                                                    </DefinedValue>
                                                    <DefinedValue>
                                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iPrimBillToAddressID" />
                                                    </DefinedValue>
                                                    <DefinedValue>
                                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iPricePlanTypeID" />
                                                    </DefinedValue>
                                                    <DefinedValue>
                                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="dtCreated" />
                                                    </DefinedValue>
                                                    <DefinedValue>
                                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="dtModified" />
                                                    </DefinedValue>
                                                    <DefinedValue>
                                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="ParentCompanyID" />
                                                    </DefinedValue>
                                                  </DefinedValues>
                                                  <Object Database="[WCDS]" Schema="[dbo]" Table="[Company]" Index="[CompanyCn_clndx]" Alias="[c]" TableReferenceId="-1" />
                                                  <SeekPredicates>
                                                    <SeekPredicate>
                                                      <Prefix ScanType="EQ">
                                                        <RangeColumns>
                                                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyCN" />
                                                          <ColumnReference Column="Uniq1004" />
                                                        </RangeColumns>
                                                        <RangeExpressions>
                                                          <ScalarOperator ScalarString="[WCDS].[dbo].[Company].[vchCompanyCN] as [c].[vchCompanyCN]">
                                                            <Identifier>
                                                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="vchCompanyCN" />
                                                            </Identifier>
                                                          </ScalarOperator>
                                                          <ScalarOperator ScalarString="[Uniq1004]">
                                                            <Identifier>
                                                              <ColumnReference Column="Uniq1004" />
                                                            </Identifier>
                                                          </ScalarOperator>
                                                        </RangeExpressions>
                                                      </Prefix>
                                                    </SeekPredicate>
                                                  </SeekPredicates>
                                                </IndexScan>
                                              </RelOp>
                                            </NestedLoops>
                                          </RelOp>
                                        </ComputeScalar>
                                      </RelOp>
                                      <RelOp NodeId="36" PhysicalOp="Compute Scalar" LogicalOp="Compute Scalar" EstimateRows="1" EstimateIO="0" EstimateCPU="1e-007" AvgRowSize="266" EstimatedTotalSubtreeCost="0.0032832" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
                                        <OutputList>
                                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Contact]" Column="vchName" />
                                        </OutputList>
                                        <ComputeScalar>
                                          <DefinedValues>
                                            <DefinedValue>
                                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Contact]" Column="vchName" />
                                              <ScalarOperator ScalarString="[WCDS].[dbo].[Contact].[vchName]">
                                                <Identifier>
                                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Contact]" Column="vchName" />
                                                </Identifier>
                                              </ScalarOperator>
                                            </DefinedValue>
                                          </DefinedValues>
                                          <RelOp NodeId="37" PhysicalOp="Clustered Index Seek" LogicalOp="Clustered Index Seek" EstimateRows="1" EstimateIO="0.003125" EstimateCPU="0.0001581" AvgRowSize="37" EstimatedTotalSubtreeCost="0.0032831" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
                                            <OutputList>
                                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Contact]" Column="vchName" />
                                            </OutputList>
                                            <IndexScan Ordered="1" ScanDirection="FORWARD" ForcedIndex="0" NoExpandHint="0">
                                              <DefinedValues>
                                                <DefinedValue>
                                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Contact]" Column="vchName" />
                                                </DefinedValue>
                                              </DefinedValues>
                                              <Object Database="[WCDS]" Schema="[dbo]" Table="[Contact]" Index="[ContactCompanyType_un_cmp_clndx]" />
                                              <SeekPredicates>
                                                <SeekPredicate>
                                                  <Prefix ScanType="EQ">
                                                    <RangeColumns>
                                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Contact]" Column="iCompanyID" />
                                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Contact]" Column="iTypeID" />
                                                    </RangeColumns>
                                                    <RangeExpressions>
                                                      <ScalarOperator ScalarString="[WCDS].[dbo].[Company].[iCompanyID] as [c].[iCompanyID]">
                                                        <Identifier>
                                                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iCompanyID" />
                                                        </Identifier>
                                                      </ScalarOperator>
                                                      <ScalarOperator ScalarString="(304)">
                                                        <Const ConstValue="(304)" />
                                                      </ScalarOperator>
                                                    </RangeExpressions>
                                                  </Prefix>
                                                </SeekPredicate>
                                              </SeekPredicates>
                                            </IndexScan>
                                          </RelOp>
                                        </ComputeScalar>
                                      </RelOp>
                                    </NestedLoops>
                                  </RelOp>
                                  <RelOp NodeId="41" PhysicalOp="Index Seek" LogicalOp="Index Seek" EstimateRows="1" EstimateIO="0.003125" EstimateCPU="0.0001581" AvgRowSize="20" EstimatedTotalSubtreeCost="0.0032831" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
                                    <OutputList>
                                      <ColumnReference Column="IsBaseRow1011" />
                                      <ColumnReference Column="Uniq1012" />
                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="iEntityID" />
                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="iEntityTypeID" />
                                    </OutputList>
                                    <IndexScan Ordered="1" ScanDirection="FORWARD" ForcedIndex="0" NoExpandHint="0">
                                      <DefinedValues>
                                        <DefinedValue>
                                          <ColumnReference Column="IsBaseRow1011" />
                                        </DefinedValue>
                                        <DefinedValue>
                                          <ColumnReference Column="Uniq1012" />
                                        </DefinedValue>
                                        <DefinedValue>
                                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="iEntityID" />
                                        </DefinedValue>
                                        <DefinedValue>
                                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="iEntityTypeID" />
                                        </DefinedValue>
                                      </DefinedValues>
                                      <Object Database="[WCDS]" Schema="[dbo]" Table="[Address]" Index="[Address_pk_ndx]" Alias="[a]" />
                                      <SeekPredicates>
                                        <SeekPredicate>
                                          <Prefix ScanType="EQ">
                                            <RangeColumns>
                                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="iAddressID" />
                                            </RangeColumns>
                                            <RangeExpressions>
                                              <ScalarOperator ScalarString="[WCDS].[dbo].[Company].[iPrimBillToAddressID] as [c].[iPrimBillToAddressID]">
                                                <Identifier>
                                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Company]" Alias="[c]" Column="iPrimBillToAddressID" />
                                                </Identifier>
                                              </ScalarOperator>
                                            </RangeExpressions>
                                          </Prefix>
                                        </SeekPredicate>
                                      </SeekPredicates>
                                    </IndexScan>
                                  </RelOp>
                                </NestedLoops>
                              </RelOp>
                              <RelOp NodeId="43" PhysicalOp="Clustered Index Seek" LogicalOp="Clustered Index Seek" EstimateRows="1" EstimateIO="0.003125" EstimateCPU="0.0001581" AvgRowSize="114" EstimatedTotalSubtreeCost="0.0032831" Parallel="0" EstimateRebinds="0" EstimateRewinds="0">
                                <OutputList>
                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="vchCity" />
                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="chStateCode" />
                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="vchProvince" />
                                  <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="nchCountryCode" />
                                </OutputList>
                                <IndexScan Lookup="1" Ordered="1" ScanDirection="FORWARD" ForcedIndex="0" NoExpandHint="0">
                                  <DefinedValues>
                                    <DefinedValue>
                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="vchCity" />
                                    </DefinedValue>
                                    <DefinedValue>
                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="chStateCode" />
                                    </DefinedValue>
                                    <DefinedValue>
                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="vchProvince" />
                                    </DefinedValue>
                                    <DefinedValue>
                                      <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="nchCountryCode" />
                                    </DefinedValue>
                                  </DefinedValues>
                                  <Object Database="[WCDS]" Schema="[dbo]" Table="[Address]" Index="[AddressEntityIDType_cmp_clndx]" Alias="[a]" TableReferenceId="-1" />
                                  <SeekPredicates>
                                    <SeekPredicate>
                                      <Prefix ScanType="EQ">
                                        <RangeColumns>
                                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="iEntityID" />
                                          <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="iEntityTypeID" />
                                          <ColumnReference Column="Uniq1012" />
                                        </RangeColumns>
                                        <RangeExpressions>
                                          <ScalarOperator ScalarString="[WCDS].[dbo].[Address].[iEntityID] as [a].[iEntityID]">
                                            <Identifier>
                                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="iEntityID" />
                                            </Identifier>
                                          </ScalarOperator>
                                          <ScalarOperator ScalarString="[WCDS].[dbo].[Address].[iEntityTypeID] as [a].[iEntityTypeID]">
                                            <Identifier>
                                              <ColumnReference Database="[WCDS]" Schema="[dbo]" Table="[Address]" Alias="[a]" Column="iEntityTypeID" />
                                            </Identifier>
                                          </ScalarOperator>
                                          <ScalarOperator ScalarString="[Uniq1012]">
                                            <Identifier>
                                              <ColumnReference Column="Uniq1012" />
                                            </Identifier>
                                          </ScalarOperator>
                                        </RangeExpressions>
                                      </Prefix>
                                    </SeekPredicate>
                                  </SeekPredicates>
                                </IndexScan>
                              </RelOp>
                            </NestedLoops>
                          </RelOp>
                        </ComputeScalar>
                      </RelOp>
                    </Sort>
                  </RelOp>
                </QueryPlan>
              </StmtSimple>
            </Statements>
          </Then>
        </StmtCond>
      </Statements>
    </Batch>
  </BatchSequence>
</ShowPlanXML>'


EXEC dbaperf.dbo.dbasp_ShowPlanAsText @doc=@doc,@PlanOutput=@PlanOutput,@PrintOutput=1,@SelectOutput=0

SET NOCOUNT ON
GO
ALTER PROCEDURE	dbasp_ShowPlanAsText
	(
	@doc xml
	,@PlanOutput nVarChar(max) = NULL OUTPUT
	,@PrintOutput bit = 0
	,@SelectOutput bit = 0
	)
AS	
DECLARE @hdoc int

DECLARE @nodenestlist TABLE (id INT, nestLevel INT,lastChild INT,spacer nvarchar(2000))
DECLARE @linelocation TABLE (columnNumber INT)
DECLARE	@plan TABLE 
	(
	[id] [bigint] NULL,
	[parentid] [bigint] NULL,
	[nodetype] [int] NULL,
	[localname] [nvarchar](4000) NULL,
	[prefix] [nvarchar](4000) NULL,
	[namespaceuri] [nvarchar](4000) NULL,
	[datatype] [nvarchar](4000) NULL,
	[prev] [bigint] NULL,
	[text] nvarchar(max) NULL
	)

--Create an internal representation of the XML document.
EXEC sp_xml_preparedocument @hdoc OUTPUT, @doc


INSERT INTO	@Plan
SELECT		* 
FROM		OPENXML (@hdoc, '/')

-- Remove the internal representation.
exec sp_xml_removedocument @hdoc

DECLARE @id			INT	
	,@parentid		INT
	,@nodetype		INT
	,@localname		nVarChar(255)
	,@prefix		nVarChar(50)
	,@namespaceuri		nVarChar(255)
	,@datatype		nVarChar(50)
	,@prev			INT
	,@text			nVarChar(max)
	,@nestLevel		INT
	,@OutputString		nVarChar(max)
	,@nodeindent		int
	,@LastChild		Int
	,@lastSpacer		nVarChar(2000)
	,@nextSpacer		nVarChar(2000)
	,@parentsLastChild	INT
	,@MaxGroupLength	INT

DECLARE	@Char_Space		nChar(1)
	,@Char_Vert		nChar(1)
	,@Char_Horiz		nChar(1)
	,@Char_Corner_TL	nChar(1)
	,@Char_Corner_TR	nChar(1)
	,@Char_Corner_BL	nChar(1)
	,@Char_Corner_BR	nChar(1)
	,@Char_T_L		nChar(1)
	,@Char_T_R		nChar(1)
	,@Char_T_T		nChar(1)
	,@Char_T_B		nChar(1)
		

SELECT	@Char_Space		= NCHAR([dbaadmin].[dbo].[HexToInt] ('00A0'))
	,@Char_Vert		= NCHAR([dbaadmin].[dbo].[HexToInt] ('2502'))
	,@Char_Horiz		= NCHAR([dbaadmin].[dbo].[HexToInt] ('2500'))
	,@Char_Corner_TL	= NCHAR([dbaadmin].[dbo].[HexToInt] ('2518'))
	,@Char_Corner_TR	= NCHAR([dbaadmin].[dbo].[HexToInt] ('2514'))
	,@Char_Corner_BL	= NCHAR([dbaadmin].[dbo].[HexToInt] ('2510'))
	,@Char_Corner_BR	= NCHAR([dbaadmin].[dbo].[HexToInt] ('250C'))
	,@Char_T_L		= NCHAR([dbaadmin].[dbo].[HexToInt] ('2524'))
	,@Char_T_R		= NCHAR([dbaadmin].[dbo].[HexToInt] ('251C'))
	,@Char_T_T		= NCHAR([dbaadmin].[dbo].[HexToInt] ('2534'))
	,@Char_T_B		= NCHAR([dbaadmin].[dbo].[HexToInt] ('252C'))

			
SET @PlanOutput = N''	
DECLARE test_cursor CURSOR
FOR
SELECT * FROM @Plan
OPEN test_cursor
FETCH NEXT FROM test_cursor INTO @id,@parentid,@nodetype,@localname,@prefix,@namespaceuri,@datatype,@prev,@text
WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN
		SELECT	@LastChild		= MAX(id) FROM @Plan WHERE parentid =  @id
		SELECT	@nestLevel		= COALESCE(nestlevel,-1) +1
			,@lastSpacer		= COALESCE(spacer,N'')
			,@parentsLastChild	= COALESCE(lastChild,0)
		FROM	@nodenestlist 
		WHERE	id = @parentid
		
		IF	@nodetype = 2 
			SET @nextSpacer = COALESCE(@lastSpacer,N'') + @Char_Space+CASE WHEN @ID < @parentsLastChild THEN @Char_T_R ELSE @Char_Corner_TR END+@Char_Horiz+@Char_Horiz
		ELSE
		BEGIN
			If	@id < @parentsLastChild
				SET @nextSpacer = COALESCE(@lastSpacer,N'') + @Char_Space+@Char_Vert+@Char_Space+@Char_Space  --N' ▕  '
			ELSE
				SET @nextSpacer = COALESCE(@lastSpacer,N'') + @Char_Space+@Char_Space+@Char_Space+@Char_Space --N'    '
		END
		
		INSERT INTO	@nodenestlist 
				(id,nestLevel,lastChild,spacer) 
		Values		(@id,@nestLevel,@LastChild,@nextSpacer)
		
		If		@nodetype = 1 
		BEGIN
			If @nestLevel > 0
			SET	@lastSpacer	= COALESCE(@lastSpacer,N'') + @Char_Space+CASE WHEN @ID < @parentsLastChild THEN @Char_T_R ELSE @Char_Corner_TR END+@Char_Horiz+@Char_Horiz
			SET	@OutputString	= REPLACE(REPLACE(REPLACE(@lastSpacer,@Char_Corner_TR,@Char_Vert),@Char_T_R,@Char_Vert),@Char_Horiz,@Char_Space) + @Char_Corner_BR +REPLICATE(@Char_Horiz,LEN(COALESCE(@localname,N'')))+@Char_Corner_BL+ CHAR(10)
						+ @lastSpacer + @Char_T_L + COALESCE(@localname,N'')+@Char_Vert+ CHAR(10)
						+ REPLACE(REPLACE(REPLACE(@lastSpacer,@Char_Corner_TR,@Char_Space),@Char_T_R,@Char_Vert),@Char_Horiz,@Char_Space) + @Char_Corner_TR +REPLICATE(@Char_Horiz,LEN(COALESCE(@localname,N'')))+@Char_Corner_TL
			SET	@PlanOutput	= @PlanOutput + COALESCE(@OutputString,'') + CHAR(13) + CHAR(10)
		END
		
		If		@nodetype = 2 
		BEGIN
			If @nestLevel > 0
			SET	@lastSpacer	= COALESCE(@lastSpacer,N'') + @Char_Space+CASE WHEN @ID < @parentsLastChild THEN @Char_T_R ELSE @Char_Corner_TR END+@Char_Horiz+@Char_Horiz
			SELECT	@MaxGroupLength	= MAX(LEN(localname)) FROM @Plan WHERE parentid =  @parentid and nodeType = 2
			SET	@OutputString	= @lastSpacer + LEFT(COALESCE(@localname,N'')+REPLICATE(@Char_Space,@MaxGroupLength),@MaxGroupLength) + @Char_Space+N':'+@Char_Space 
		END

		If		@nodetype = 3 
		BEGIN
			SET	@lastSpacer	= REPLACE(REPLACE(REPLACE(COALESCE(@lastSpacer,N''),@Char_Corner_TR,@Char_Space),@Char_Horiz,@Char_Space),@Char_T_R,@Char_Vert) + REPLICATE(@Char_Space,@MaxGroupLength+2)
			SET	@OutputString	= @OutputString + REPLACE(COALESCE(@text,''),CHAR(10),CHAR(10)+ @lastSpacer) 
			SET	@PlanOutput	= @PlanOutput + COALESCE(@OutputString,N'') + CHAR(13) + CHAR(10)
		END
		--PRINT	@OutputString
	END
	FETCH NEXT FROM test_cursor INTO @id,@parentid,@nodetype,@localname,@prefix,@namespaceuri,@datatype,@prev,@text
END

CLOSE test_cursor
DEALLOCATE test_cursor

IF @PrintOutput = 1
BEGIN
	DECLARE @Marker1 bigint, @Marker2 bigint
	SET	@Marker1 = 0

	PrintMore:
		--EXPECTING TO BREAK ON CR&LF

	SET	@Marker2 = CHARINDEX(CHAR(13),@PlanOutput,@Marker1 + 3500)
	IF	@Marker2 = 0
		SET @Marker2 = LEN(@PlanOutput)

	SET	@OutputString = SUBSTRING(@PlanOutput,@Marker1,@Marker2-@Marker1)
	PRINT	@OutputString

	SET	@Marker1 = @Marker2 + 2 -- USE +2 instead of + 1 to STRIP CRLF

	If	@Marker2 < LEN(@PlanOutput)
		GOTO PrintMore
END	
IF @SelectOutput = 1
	SELECT @PlanOutput AS [PlanOutput]
GO


