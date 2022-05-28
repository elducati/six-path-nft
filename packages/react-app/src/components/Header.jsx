import { PageHeader } from "antd";
import React from "react";

// displays a page header

export default function Header() {
  return (
    <a href="/">
      <div style={{ position: "absolute", left: -10, top: -5 }}>
        <img src="sixpath.svg" width="130" height="100" alt="TruthSeeker" />
      </div>
      <PageHeader
        title={<div style={{ marginLeft: 70 }}>SixPath</div>}
        subTitle="The Sage of the SixPath Symbol"
        style={{ cursor: "pointer" }}
      />
    </a>
  );
}
