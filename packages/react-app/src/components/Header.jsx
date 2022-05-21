import { PageHeader } from "antd";
import React from "react";

// displays a page header

export default function Header() {
  return (
    <a href="/">
      <div style={{ position: "absolute", left: -10, top: -5 }}>
        <img src="truth-seeker1.svg" width="130" height="130" alt="TruthSeeker" />
      </div>
      <PageHeader
        title={<div style={{ marginLeft: 50 }}>TruthSeeker</div>}
        subTitle="With artefacts as accesories"
        style={{ cursor: "pointer" }}
      />
    </a>
  );
}
