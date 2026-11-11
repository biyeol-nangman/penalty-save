# 패널티킥 세이브 (Vercel + Supabase)

링크만 열면 누구나 플레이하고, 기록은 Supabase에 저장되어 모두가 같은 순위표를 봅니다.
빌드 과정이 없는 정적 사이트라서 설정은 세 단계입니다.

```
index.html     게임 화면 (이 파일 하나가 전체 게임)
config.js      Supabase 주소와 키를 넣는 곳  ← 직접 수정
supabase.sql   순위표 테이블과 보안 규칙     ← Supabase에서 한 번 실행
```

## 1. Supabase에 순위표 만들기

1. https://supabase.com 에서 로그인하고 **New project** 로 프로젝트를 만듭니다. 이름과 DB 비밀번호는 아무거나 괜찮고, 리전은 Northeast Asia (Seoul)가 가깝습니다.
2. 프로젝트가 준비되면 왼쪽 메뉴 **SQL Editor** → **New query** 를 엽니다.
3. `supabase.sql` 내용을 전부 붙여 넣고 **Run** 을 누릅니다. `Success` 가 나오면 끝입니다.
4. 왼쪽 **Table Editor** 에 `scores` 테이블이 보이면 정상입니다.

## 2. 주소와 키를 config.js에 넣기

1. Supabase 왼쪽 아래 **Project Settings** → **API** (또는 **API Keys**) 로 갑니다.
2. 아래 두 값을 복사합니다.
   - **Project URL** (예: `https://abcdxyz.supabase.co`)
   - **anon public** 키 (새 화면에서는 **Publishable key**, `sb_publishable_...`). 둘 중 보이는 쪽을 쓰면 됩니다.
3. `config.js` 의 `YOUR-...` 두 곳을 복사한 값으로 바꿉니다.

`service_role` / `secret` 키는 절대 넣지 마세요. 이 키는 모든 보안 규칙을 무시합니다.

## 3. Vercel에 올리기

방법 A. GitHub 사용 (추천, 이후 수정이 쉬움)
1. 이 폴더를 GitHub 저장소로 올립니다.
2. https://vercel.com → **Add New… → Project** → 그 저장소를 **Import**.
3. 설정은 그대로 둡니다. Framework Preset 은 **Other**, Build Command 와 Output Directory 는 비워 둡니다.
4. **Deploy** 를 누르면 `https://프로젝트이름.vercel.app` 주소가 생깁니다.

방법 B. 명령어 사용
```
cd 이 폴더
npx vercel --prod
```
처음에는 로그인과 몇 가지 질문이 나오는데 모두 기본값(엔터)으로 진행하면 됩니다.

## 4. 친구에게 링크 공유하기

배포된 주소를 보내면 로그인 없이 바로 플레이할 수 있습니다.

친구가 Vercel 로그인 화면을 보게 된다면 Vercel 프로젝트의 **Settings → Deployment Protection** 에서 보호 기능을 꺼야 합니다. 프로젝트 기본값에 따라 미리보기 주소만 보호되는 경우도 있어서, 열어 보고 판단하세요.

## 동작 방식과 주의할 점

- 한 사람은 브라우저에 저장된 익명 ID 하나로 구분됩니다. 한 사람당 최고 기록 하나만 순위표에 남고, 이름과 팀은 마지막으로 쓴 값으로 바뀝니다. 브라우저를 바꾸거나 사이트 데이터를 지우면 새 사람으로 시작합니다.
- 로그인이 없어서 가짜 기록을 완전히 막을 수는 없습니다. 서버는 선방 500 이하, 속도 300 이하인 값만 받습니다. 이상한 기록은 Supabase **Table Editor → scores** 에서 해당 줄을 지우면 됩니다.
- 순위표는 20초마다 자동으로 새로 고침됩니다.
- Supabase 무료 프로젝트는 일주일 정도 아무도 쓰지 않으면 일시 중지됩니다. 중지되면 대시보드에서 **Restore** 를 누르면 다시 켜지고 기록은 그대로 남습니다.
- 환경 변수는 쓰지 않습니다. 정적 사이트라서 키는 `config.js` 에 직접 들어가며, 이 키는 공개되어도 되는 키입니다.
