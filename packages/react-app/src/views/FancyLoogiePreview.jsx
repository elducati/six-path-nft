import React, { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { Alert, Button, Card, Col, Input, List, Menu, Row, Tabs, Dropdown, Badge } from "antd";
import { DownOutlined } from "@ant-design/icons";
import { Address, AddressInput } from "../components";
import { ethers } from "ethers";
const { TabPane } = Tabs;

function FancyLoogiePreview({
  DEBUG,
  readContracts,
  writeContracts,
  tx,
  address,
  updateBalances,
  setUpdateBalances,
  nfts,
  nftsSvg,
  fancyLoogiesNfts,
  selectedFancyLoogie,
  selectedFancyLoogiePreview,
  setSelectedFancyLoogiePreview,
  selectedNfts,
  setSelectedNfts,
  setFancyLoogiesNfts,
  fancyLoogiePreviewActiveTab,
  setFancyLoogiePreviewActiveTab,
}) {
  useEffect(() => {
    const updatePreview = async () => {
      if (DEBUG) console.log("Updating preview...");
      if (selectedFancyLoogie) {
        let nftUpdate = {};
        const loogieSvg = await readContracts.FancyLoogie.renderTokenById(selectedFancyLoogie);
        let nftsSvg = "";
        for (const nft of nfts) {
          if (selectedNfts[nft]) {
            nftsSvg += await readContracts[nft].renderTokenById(selectedNfts[nft]);
          }
          const svg =
            '<svg width="300" height="349"  xmlns="http://www.w3.org/2000/svg">' +
            loogieSvg +
            '<g class="bow"  transform="translate(47,-12) scale(0.8 0.8)">' +
            nftsSvg +
            "</g>" +
            "</svg>";
          setSelectedFancyLoogiePreview(svg);
        }
      } else {
        setSelectedFancyLoogiePreview("");
      }
    };
    updatePreview();
  }, [address, selectedFancyLoogie, selectedNfts, updateBalances]);

  return (
    <>
      {selectedFancyLoogiePreview ? (
        <div class="fancy-loogie-preview">
          <Card
            style={{ width: 400 }}
            title={
              <div style={{ height: 45 }}>
                <span style={{ fontSize: 18, marginRight: 8 }}>Selected FancyLoogie #{selectedFancyLoogie}</span>
              </div>
            }
          >
            <div dangerouslySetInnerHTML={{ __html: selectedFancyLoogiePreview }}></div>
            <Tabs
              activeKey={fancyLoogiePreviewActiveTab}
              onChange={tab => setFancyLoogiePreviewActiveTab(tab)}
              type="card"
            >
              {nfts.map(function (nft) {
                return (
                  <TabPane
                    tab={
                    <div>
                      <svg width="40" height="40" xmlns="http://www.w3.org/2000/svg" style={{ float: "left" }}>
                        {nftsSvg[nft]}
                      </svg>
                    </div>
                  }
                    key={"preview-" + nft}
                  >
                    {fancyLoogiesNfts &&
                      fancyLoogiesNfts[selectedFancyLoogie] &&
                      fancyLoogiesNfts[selectedFancyLoogie][readContracts[nft].address] > 0 ? (
                      <div>
                        Wearing {nft} #{fancyLoogiesNfts[selectedFancyLoogie][readContracts[nft].address]}
                        <Button
                          className="action-inline-button"
                          onClick={() => {
                            tx(writeContracts.FancyLoogie.removeNftFromLoogie(readContracts[nft].address, selectedFancyLoogie), function (transaction) {
                              setFancyLoogiesNfts(prevState => ({
                                ...prevState,
                                [selectedFancyLoogie]: {
                                  ...prevState[selectedFancyLoogie],
                                  [readContracts[nft].address]: 0
                                }
                              }));
                              setUpdateBalances(updateBalances + 1);
                            });
                          }}
                        >
                          Remove {nft}
                        </Button>
                      </div>
                    ) : (
                      <div>
                        {selectedNfts[nft] ? (
                          <div>
                            <span>Previewing #{selectedNfts[nft]}</span>
                            {fancyLoogiesNfts &&
                              fancyLoogiesNfts[selectedFancyLoogie] &&
                              fancyLoogiesNfts[selectedFancyLoogie][readContracts[nft].address] == 0 && (
                                <Button
                                  type="primary"
                                  className="action-inline-button"
                                  onClick={() => {
                                    const tankIdInBytes =
                                      "0x" + parseInt(selectedFancyLoogie).toString(16).padStart(64, "0");

                                    tx(
                                      writeContracts[nft]["safeTransferFrom(address,address,uint256,bytes)"](
                                        address,
                                        readContracts.FancyLoogie.address,
                                        selectedNfts[nft],
                                        tankIdInBytes,
                                      ),
                                      function (transaction) {
                                        setSelectedNfts(prevState => ({
                                          ...prevState,
                                          [nft]: null,
                                        }));
                                        setFancyLoogiesNfts(prevState => ({
                                          ...prevState,
                                          [selectedFancyLoogie]: {
                                            ...prevState[selectedFancyLoogie],
                                            [readContracts[nft].address]: selectedNfts[nft]
                                          }
                                        }));
                                        setUpdateBalances(updateBalances + 1);
                                      },
                                    );
                                  }}
                                >
                                  Transfer
                                </Button>
                              )}
                          </div>
                        ) : (
                          <span>Select a {nft} to preview</span>
                        )}
                      </div>
                    )
                    }
                  </TabPane>
                )
              })}
            </Tabs>
          </Card>
        </div>
      ) : (
        <div class="fancy-loogie-preview">
          <Card
            style={{ width: 400 }}
            title={
              <div style={{ height: 45 }}>
                <span style={{ fontSize: 18, marginRight: 8 }}>No TruthSeeker selected</span>
              </div>
            }
          >
            <div style={{ position: "relative" }}>
              <img src="truth-seeker.svg" width="400" height="400" alt="TruthSeeker" />
            </div>
            <div style={{ height: 90 }}>
              Select a TruthSeeker from the <strong>TruthSeeker</strong> Tab to wear.
            </div>
          </Card>
        </div>
      )}
    </>
  );
}

export default FancyLoogiePreview;
