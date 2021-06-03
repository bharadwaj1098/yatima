use libipld::{
  cid::Cid,
  cbor::DagCborCodec,
  codec::Codec,
  ipld::Ipld,
};
use yatima_core::cid::cid;
use yatima_utils::{
  store::{Store},
};
use web_sys::{
  self,
  Window,
  Storage,
};

#[derive(Debug, Clone)]
pub struct WebStore {
  window: Window,
  storage: Storage,
}

#[wasm_bindgen(module = "ipfs")]
extern {
  ipfs
}

impl WebStore {
  pub fn new() -> Self {
    let window = web_sys::window().expect("should have a window in this context");
    let storage = window.local_storage().expect("should have local storage").unwrap();
    WebStore {
      window,
      storage,
    }
  }
}

impl Store for WebStore {
  fn get(&self, link: Cid) -> Option<Ipld> {

    self.storage.get(link).ok();
    // TODO
    None
  }

  fn put(&self, expr: Ipld) -> Cid {
    let link = cid(&expr);
    let data = DagCborCodec.encode(&expr).unwrap();
    match self.storage.set(link,data) {
      Ok(()) => (),
      Err(e) => log("Failed to put to local_storage"),
    }

    // TODO

    link
  }
}

