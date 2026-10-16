export default function Home() {
  return (
    <main className="mx-auto max-w-3xl px-6 py-24">
      <p className="mb-4 text-sm font-semibold tracking-widest text-teal-800">
        CIC / P0
      </p>
      <h1 className="text-4xl font-semibold tracking-tight sm:text-5xl">
        Cloud Incident Commander
      </h1>
      <p className="mt-8 text-lg leading-relaxed">
        Nền tảng vận hành sự cố trên AWS, với phân tích có dẫn chứng và phê
        duyệt của con người trước khi khắc phục.
      </p>
      <p className="mt-6 border-l-2 border-teal-700 pl-4 leading-relaxed">
        Đang ở giai đoạn thiết lập P0. Kết nối AWS, đăng nhập và dữ liệu sự cố
        sẽ được triển khai từ P1. Chưa có hạ tầng cloud nào được triển khai.
      </p>
    </main>
  );
}
